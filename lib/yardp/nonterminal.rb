# frozen_string_literal: true

require_relative 'util'

module Yardp
  class Nonterminal
    attr_accessor :id, :children

    def initialize(id, *children)
      @id = id
      @children = children.flatten.map do |c|
        c.is_a?(Nonterminal) ? c : Terminal.new(c)
      end
      @assert = false
    end

    def parse(text, opts = {})
      ret = apply(text, 0, opts, 0)
      ret[0]
    end

    def apply(text, pos, opts, depth)
      apply_impl(text, pos, opts, depth)
    end

    def to_a
      @children
    end

    def to_h
      { id: @id, children: @children.map(&:to_h) }
    end

    begin
      require 'ruby-graphviz'

      def graphviz(g = nil, parent = nil, index = 0)
        g = GraphViz.new(:G, type: :digraph) if g.nil?

        label = @id == :terminal ? to_s : @id.to_s
        shape = @id == :terminal ? :circle : :rectangle
        label = label.gsub('\\', '\\\\\\')
        node = g.add_nodes(parent.nil? ? @id.to_s : "#{parent.id},#{index}", label: label, shape: shape)
        g.add_edges(parent, node) unless parent.nil?

        @children.each_with_index do |c, i|
          c.graphviz(g, node, i)
        end

        g
      end
    rescue LoadError
      # Do nothing
    end

    def assert
      @assert = true
      self
    end

    protected

    def apply_impl(_text, _pos, _opts, _depth)
      raise 'Not implemented.'
    end

    def strip_whitespace(text, pos, opts)
      return pos unless opts[:strip_whitespace]

      pos += 1 while opts[:whitespace_chars].include? text[pos]

      pos
    end
  end
end

require_relative 'concat'
require_relative 'alternation'
require_relative 'repeat'
require_relative 'maybe'

module Yardp
  class Nonterminal
    def >>(other)
      return other >> self if other.is_a?(Concat)

      Concat.new([self, other])
    end

    def |(other)
      return other | self if other.is_a?(Alternation)

      Alternation.new([self, other])
    end

    def repeat(min = 0, max = -1)
      Repeat.new(min, max, self)
    end

    def repeat!(min = 0, max = -1)
      repeat(min, max).assert
    end

    def *(other)
      case other
      when Integer then repeat(other, other)
      when Range then repeat(other.min, other.max)
      else raise Error, 'Expected Integer or Range in * operator.'
      end
    end

    def maybe
      Maybe.new(self)
    end
  end
end
