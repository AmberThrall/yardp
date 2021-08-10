# frozen_string_literal: true

require_relative 'util'

module Yardp
  class ParseTree
    attr_reader :rule, :string, :children, :parent

    def initialize(rule, string, children = [], *flags)
      @rule = rule
      @string = string
      @children = Array(children)
      @children.each { |c| c.parent = self }
      @flags = flags
    end

    def failed?
      @flags.include? :failed
    end

    def to_s
      @string
    end

    def parent=(parent)
      @parent.children.delete(self) unless @parent.nil?
      @parent = parent
    end

    def graphviz(g = nil, parent = nil, index = 0)
      g = GraphViz.new(:G, type: :digraph) if g.nil?

      label = @rule == :terminal ? Util.sanitize_string(@string) : @rule.to_s
      label += ' (fail)' if failed?
      label = label.gsub("\\", "\\\\\\")
      shape = @rule == :terminal ? :circle : :rectangle
      node = g.add_nodes(parent.nil? ? @rule.to_s : "#{parent.id},#{index}", label: label, shape: shape)
      g.add_edges(parent, node) unless parent.nil?

      @children.each_with_index do |c, i|
        c.graphviz(g, node, i)
      end

      g
    end

    def pretty_print(spaces = 2, level = 0)
      print ['┃', ' ' * spaces].join * (level - 1) if level.positive?
      print '┗━' if level.positive?

      puts "#{@rule} (#{Util.sanitize_string(@string, 0, 10)})#{failed? ? ' (fail)' : ''}"
      @children.each do |c|
        c.pretty_print(spaces, level + 1)
      end
    end

    def to_h
      {
        rule: @rule,
        string: @string,
        children: @children.map(&:to_h)
      }
    end

    def [](arg)
      child(arg)
    end

    def child?(rule)
      rule = rule.to_sym
      !@children.filter { |x| x.rule == rule }.empty?
    end

    def child(arg)
      case arg
      when Symbol, String
        arg = arg.to_sym
        c = @children.filter { |x| x.rule == arg }
        return nil if c.empty?
        return c.first if c.length == 1

        c
      else @children[arg]
      end
    end

    def delete_rule(rule, recursive: false)
      @children.delete_if { |c| c.rule == rule }
      @children.each { |c| c.delete_rule(rule, recursive: recursive) } if recursive
    end

    def simplify
      loop do
        new_children = []
        @children.each do |c|
          case c.rule
          when :maybe, :repeat, :concat, :alternation then new_children.concat c.children.map(&:simplify)
          else new_children << c.simplify
          end
        end
        break if @children == new_children

        @children = new_children
      end

      @string = @children[0].string if @children.length == 1 && @children[0].rule == :m
      self
    end
  end
end
