# frozen_string_literal: true

require_relative 'nonterminal'
require_relative 'parse_error'
require_relative 'terminal'

module Yardp
  class Alternation < Nonterminal
    def initialize(children)
      super(:alternation, children)
    end

    def |(other)
      other = Terminal.new(other) unless other.is_a?(Nonterminal)
      @children.concat other.children if other.is_a?(Alternation)
      @children << other unless other.is_a?(Alternation)
      self
    end

    protected

    def apply_impl(text, pos, opts, depth)
      pos = strip_whitespace(text, pos, opts)

      attempts = []
      @children.each do |c|
        tree, new_pos = c.apply(text, pos, opts, depth + 1)
        attempts << tree if opts[:include_failed]
        next if tree.failed?

        return [ParseTree.new(:alternation, tree.string, tree), new_pos]
      end

      raise ParseError.new(pos, 'Alternation found no matches', text) if @assert

      [ParseTree.new(:alternation, '', attempts, :failed), -1]
    end
  end
end
