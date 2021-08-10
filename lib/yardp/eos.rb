# frozen_string_literal: true

require_relative 'nonterminal'

module Yardp
  class Eos < Nonterminal
    def initialize
      super(:eos)
    end

    protected

    def apply_impl(text, pos, opts, _depth)
      pos = strip_whitespace(text, pos, opts)
      unless pos >= text.length
        raise ParseError.new(pos, "Expected end of string but encountered '#{text[pos]}'", text) if @assert

        return [ParseTree.new(:eos, '', [], :failed), -1]
      end

      [ParseTree.new(:eos, ''), pos + 1]
    end
  end
end
