# frozen_string_literal: true

require_relative 'nonterminal'

module Yardp
  class Repeat < Nonterminal
    attr_accessor :min, :max

    def initialize(min, max, nonterminal)
      super(:repeat, nonterminal)
      @min = min
      @max = max
    end

    protected

    def apply_impl(text, pos, opts, depth)
      matches = []
      last_tree = nil
      loop do
        pos = strip_whitespace(text, pos, opts)
        tree, new_pos = @children.first.apply(text, pos, opts, depth + 1)
        last_tree = tree
        break if tree.failed?

        matches << tree
        pos = new_pos
      end

      if matches.length < @min || (matches.length > @max && @max >= 0)
        raise ParseError.new(pos, 'Not enough matches for repeated term', text) if matches.length < @min && @assert
        raise ParseError.new(pos, 'Too many enough matches for repeated term', text) if @assert

        matches << last_tree if opts[:include_failed]
        return [ParseTree.new(:repeat, '', opts[:include_failed] ? matches : [], :failed), -1]
      end

      matches << last_tree if opts[:include_failed]
      [ParseTree.new(:repeat, matches.map(&:string).join, matches), pos]
    end
  end
end
