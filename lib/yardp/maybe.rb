# frozen_string_literal: true

require_relative 'nonterminal'

module Yardp
  class Maybe < Nonterminal
    def initialize(nonterminal)
      super(:maybe, nonterminal)
    end

    protected

    def apply_impl(text, pos, opts, depth)
      tree, new_pos = @children.first.apply(text, pos, opts, depth + 1)
      return [ParseTree.new(:maybe, '', opts[:include_failed] ? tree : []), pos] if tree.failed?

      [ParseTree.new(:maybe, tree.string, tree), new_pos]
    end
  end
end
