# frozen_string_literal: true

require_relative 'rule'
require_relative '../yardp'

module Yardp
  module ParserMixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def rules
        @defined_rules
      end

      def options
        default_options if @options.nil?
        @options
      end

      def option(opt, value = nil)
        default_options if @options.nil?
        @options[opt] = value
      end

      def debug
        option(:include_failed, true)
        option(:simplify_parse_tree, false)
      end

      def default_options
        @options = {
          strip_whitespace: true,
          whitespace_chars: ["\x00", "\t", "\n", "\v", "\f", "\r", ' '],
          case_sensitive: true,
          include_failed: false,
          simplify_parse_tree: true
        }
      end

      def token(name, arg, *flags)
        name = name.to_sym
        raise StandardError, "Token '#{name}' already defined." if const_defined?(name)

        const_set(name, Terminal.new(arg, *flags))
      end

      def rule(name, opts = {}, &block)
        name = name.to_sym
        if method_defined?(name) || method_defined?("#{name}?".to_sym) || method_defined?("#{name}!".to_sym)
          raise StandardError, "Rule '#{name}' already defined."
        end

        @defined_rules ||= []
        @defined_rules << name

        define_method(name) do
          @rules ||= {}
          return @rules[name] if @rules.key?(name)

          block_closure = proc { instance_exec(&block) }
          @rules[name] = Rule.new(name, opts, &block_closure)
        end

        define_method("#{name}?".to_sym) { send(name).maybe }
        define_method("#{name}!".to_sym) { send(name).assert }
      end

      def start(name)
        undef_method :get_start if method_defined? :get_start
        define_method(:get_start) { send(name.to_sym) }
      end

      def abnf(grammar)
        # Core tokens
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

        # Define the santizier
        define_method(:sanitize_abnf_element) do |element|
          if element.is_a?(Rule)
            if element.id.to_s.upcase == element.id.to_s && self.class.const_defined?(element.id)
              return self.class.const_get(element.id)
            end

            send(element.id)
          else
            element.children = element.children.map { |x| sanitize_abnf_element(x) }
            element
          end
        end

        # Parse the grammar
        parser = Yardp::Grammars::ABNF.new
        tree = parser.parse(grammar)
        tree.graphviz.output(png: 'abnf.png')

        parser.def_rules.each do |name, element|
          rule(name) { sanitize_abnf_element(element) }
        end
      end
    end
  end
end
