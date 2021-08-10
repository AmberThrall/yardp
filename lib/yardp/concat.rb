# frozen_string_literal: true

require_relative 'nonterminal'
require_relative 'terminal'

module Yardp
  class Concat < Nonterminal
    def initialize(children)
      super(:concat, children)
    end

    def >>(other)
      other = Terminal.new(other) unless other.is_a?(Nonterminal)
      @children.concat other.children if other.is_a?(Concat)
      @children << other unless other.is_a?(Concat)
      self
    end

    protected

    def apply_impl(text, pos, opts, depth)
      matches = []
      @children.each do |c|
        pos = strip_whitespace(text, pos, opts)
        tree, new_pos = c.apply(text, pos, opts, depth + 1)
        matches << tree if opts[:include_failed]
        if tree.failed?
          raise ParseError.new(pos, "Failed to match #{c.id} in concatenation", text) if @assert

          return [ParseTree.new(:concat, '', opts[:include_failed] ? matches : [], :failed), -1]
        end
        matches << tree unless opts[:include_failed]
        pos = new_pos
      end

      [ParseTree.new(:concat, matches.map(&:string).join, matches), pos]
    end
  end
end
