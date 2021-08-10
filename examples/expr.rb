# frozen_string_literal: true

require_relative '../lib/yardp'

class ExprParser < Yardp::Grammar
  start(:expression)

  rule(:expression) { (integer >> operator >> expression) | integer }
  rule(:operator) { t(/[+-]/) }
  rule(:integer) { t(['+', '-']).maybe >> t(/[0-9]+/) }
end

parser = ExprParser.new
parser.parse('53 + 28 - 17').graphviz.output(png: 'expr.png')
