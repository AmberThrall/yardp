# frozen_string_literal: true

require_relative '../grammar'

module Yardp
  module Grammars
    # An Augmented Backus-Naur form parser taken from https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form
    class ABNF < Yardp::Grammar
      start(:rulelist)
      option(:strip_whitespace, false)

      # Core rules
      token(:ALPHA, /[A-Za-z]/)
      token(:DIGIT, /[0-9]/)
      token(:HEXDIG, /[0-9A-Fa-f]/)
      token(:DQUOTE, '"')
      token(:SP, ' ')
      token(:HTAB, "\t")
      token(:WSP, [' ', "\t"])
      token(:LWSP, /(?:(?:\r\n)?[ \t])*/)
      token(:VCHAR, /[\u0021-\u007E]/)
      token(:CHAR, /[\u0001-\u007F]/)
      token(:OCTET, /[\u0000-\u00FF]/)
      token(:CTL, /[\u0000-\u001F\u007F]/)
      token(:CR, "\r")
      token(:LF, "\n")
      token(:CRLF, "\r\n")
      token(:BIT, %w[0 1])
      token(:CHAR2, ["\u0020", "\u0021", /[\u0023-\u007E]/])
      token(:CHAR3, ["\u000A", /[\u0020-\u003D]/, /[\u003F-\u007E]/])

      # Actual grammar
      rule(:rulelist) { repeat(c_wsp | c_nl | rule) >> eos! }
      rule(:rule) { rulename >> defined_as >> elements >> c_nl }
      rule(:rulename) { ALPHA >> repeat(ALPHA | DIGIT | t('-') | t('_')) }
      rule(:defined_as) { c_wsp.repeat >> t(['=/', '=']) >> c_wsp.repeat }
      rule(:elements) { alt >> c_wsp.repeat }
      rule(:c_wsp) { WSP | (c_nl >> WSP) }
      rule(:c_nl) { comment | eol }
      rule(:comment) { t(';') >> repeat(WSP | VCHAR) >> eol }
      rule(:alt) { concatenation >> repeat(c_wsp.repeat >> t('/') >> c_wsp.repeat >> concatenation) }
      rule(:concatenation) { repetition >> repeat(c_wsp.repeat(1) >> repetition) }
      rule(:repetition) { repeated? >> element }
      rule(:repeated) { (DIGIT.repeat >> t('*') >> DIGIT.repeat) | DIGIT.repeat(1) }
      rule(:element) { rulename | group | option | char_val | num_val }
      rule(:group) { t('(') >> c_wsp.repeat >> alt >> c_wsp.repeat >> t(')') }
      rule(:option) { t('[') >> c_wsp.repeat >> alt >> c_wsp.repeat >> t(']') }
      rule(:char_val) { DQUOTE >> t(/[\u0020-\u0021\u0023-\u007E]*/) >> DQUOTE }
      rule(:num_val) { t('%') >> (bin_val | dec_val | hex_val) }
      rule(:bin_val) { t('b') >> BIT.repeat(1) >> maybe(repeat(t('.') >> BIT.repeat(1), 1) | (t('-') >> BIT.repeat(1))) }
      rule(:dec_val) { t('d') >> DIGIT.repeat(1) >> maybe(repeat(t('.') >> DIGIT.repeat(1), 1) | (t('-') >> DIGIT.repeat(1))) }
      rule(:hex_val) { t('x') >> HEXDIG.repeat(1) >> maybe(repeat(t('.') >> HEXDIG.repeat(1), 1) | (t('-') >> HEXDIG.repeat(1))) }
      # rule(:prose_val) { t('<') >> t(/[\u0020-\u003D\u003F-\u007E]*/) >> t('>') }

      def parse(text)
        @def_rules = {}

        text = text.lines.map(&:rstrip).filter { |x| !x.empty? }.join("\r\n")
        lpadding_size = text.lines.map { |x| x.match(/\s*./)&.to_s&.length }.filter { |x| !x.nil? }.min - 1
        text = text.lines.map { |x| x[lpadding_size..] }.join
        tree = super(text)
        tree.delete_rule(:c_wsp, recursive: true)
        tree.delete_rule(:c_nl, recursive: true)
        handle_rulelist(tree)
        tree
      end

      attr_reader :def_rules

      private

      def handle_rulelist(list)
        Array(list[:rule]).each { |x| handle_rule(x) }
      end

      def handle_rule(rule)
        defined_as = rule[:defined_as].string
        rulename = handle_rulename(rule[:rulename]).id
        elements = handle_alt(rule[:elements][:alt])

        @def_rules[rulename] = case defined_as.strip
                           when '=' then elements
                           when '=/' then @def_rules[rulename] | elements
                           else raise Error, "Expected '=' or '=/' in rule #{rulename}."
                           end
      end

      def handle_alt(alt)
        concats = Array(alt[:concatenation])
        elements = concats.map { |x| handle_concatenation(x) }

        alt = elements.first
        elements[1..].each { |x| alt |= x }
        alt
      end

      def handle_concatenation(concat)
        repetitions = Array(concat[:repetition])
        elements = repetitions.map do |x|
          element = handle_element(x[:element])
          element = handle_repeated(x[:repeated], element) if x[:repeated]
          element
        end
        return nil if elements.empty?

        c = elements.first
        elements[1..].each { |x| c = c >> x }
        c
      end

      def handle_repeated(repeated, element)
        if repeated.string.include?('*')
          parts = repeated.string.partition('*')
          min = parts[0].to_i
          max = parts[2].empty? ? -1 : parts[2].to_i
          element.repeat(min, max)
        else
          digits = repeated.string.to_i
          element.repeat(digits, digits)
        end
      end

      def handle_element(element)
        case element[0].rule
        when :rulename then handle_rulename(element[0])
        when :group then handle_group(element[0])
        when :option then handle_option(element[0])
        when :char_val then t(element[0].string[1..-2])
        when :num_val then handle_numval(element[0])
        when :prose_val then t(element[0].string[1..-2])
        end
      end

      def handle_group(group)
        handle_alt(group[:alt])
      end

      def handle_option(option)
        handle_alt(option[:alt]).maybe
      end

      def handle_numval(numval)
        if numval[:bin_val]
          base = 2
          numval = numval[:bin_val]
        elsif numval[:dec_val]
          base = 10
          numval = numval[:dec_val]
        else
          base = 16
          numval = numval[:hex_val]
        end

        if numval.string.include?('-')
          parts = numval.string.partition('-')
          start = parts[0][1..].to_i(base)
          end_char = parts[2].to_i(base)
          Terminal.new(Regexp.new("[#{start.chr}-#{end_char.chr}]"))
        elsif numval.string.include?('.')
          Terminal.new(numval.string[1..].split('.').map { |x| x.to_i(base).chr }.join)
        else
          val = numval.string[1..].to_i(base)
          Terminal.new(val.chr)
        end
      end

      def handle_rulename(rulename)
        name = rulename.string.to_sym
        Rule.new(name, nil)
      end
    end
  end
end
