# frozen_string_literal: true

require_relative 'nonterminal_methods'
require_relative 'mixin'
require_relative 'parse_tree'
require_relative 'parse_error'
require_relative 'terminal'
require_relative 'alternation'
require_relative 'eos'
require_relative 'eol'

module Yardp
  class Grammar
    include ParserMixin
    include NonterminalMethods

    def parse(text)
      ret = get_start.parse(text, self.class.options)
      raise Error, 'Parse returned a nil tree.' if ret.nil?

      # unless text[ret[1]..].strip.empty?
      #   raise ParseError.new(ret[1], "Expected end of string but encountered '#{text[ret[1] + 1]}'", text)
      # end

      ret[0].simplify if self.class.options[:simplify_parse_tree]
      ret[0]
    end

    def graphviz
      g = nil
      self.class.rules.each { |rule| g = send(rule).graphviz(g) }
      g
    end
  end
end
