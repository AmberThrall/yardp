# frozen_string_literal: true

require_relative 'nonterminal'

module Yardp
  class Eol < Nonterminal
    def initialize
      super(:eol)
    end

    protected

    def apply_impl(text, pos, opts, _depth)
      if text[pos] == "\n"
        [ParseTree.new(:eol, "\n"), pos + 1]
      elsif text[pos] == "\r" && text[pos + 1] == "\n"
        [ParseTree.new(:eol, "\r\n"), pos + 2]
      elsif strip_whitespace(text, pos, opts) == text.length
        [ParseTree.new(:eol, ''), pos + 1]
      else
        raise ParseError.new(pos, "Expected end of line but encountered '#{text[pos]}'", text) if @assert

        [ParseTree.new(:eol, '', [], :failed), -1]
      end
    end
  end
end
