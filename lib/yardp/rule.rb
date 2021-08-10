# frozen_string_literal: true

require_relative 'nonterminal'
require_relative 'terminal'

module Yardp
  class Rule < Nonterminal
    def initialize(name, opts = {}, &block)
      super(name)
      @override_options = opts
      @block = block
    end

    def graphviz(g = nil, parent = nil, index = 0)
      g = GraphViz.new(:G, type: :digraph) if g.nil?

      node = g.add_nodes(parent.nil? ? @id.to_s : "#{parent.id},#{index}", label: @id.to_s, shape: :rectangle)
      g.add_edges(parent, node) unless parent.nil?
      return g unless parent.nil?

      @block.call.graphviz(g, node, 0)

      g
    end

    protected

    def apply_impl(text, pos, opts, depth)
      if @override_options.empty?
        rule_opts = opts
      else
        rule_opts = opts.clone
        @override_options.each { |option, value| rule_opts[option] = value }
      end

      nonterminal = @block.call
      nonterminal = Terminal.new(nonterminal) unless nonterminal.is_a?(Nonterminal)
      tree, new_pos = nonterminal.apply(text, pos, rule_opts, depth + 1)
      raise ParseError.new(pos, "Failed to match rule '#{@id}'", text) if tree.failed? && @assert

      return [ParseTree.new(@id, '', opts[:include_failed] ? tree : [], :failed), -1] if tree.failed?

      [ParseTree.new(@id, tree.string, tree), new_pos]
    end
  end
end
