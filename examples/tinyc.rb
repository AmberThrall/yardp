# frozen_string_literal: true

require_relative '../lib/yardp'

# A tiny C parser. Grammer is adapted from https://gist.github.com/KartikTalwar/3095780
class TinyCParser < Yardp::Parser
  start(:program)

  rule(:program) { statement }
  rule(:statement) do
    (m('if') & paren_expr & statement & (m('else') & statement).maybe) |
      (m('while') & paren_expr & statement) |
      (m('do') & statement & m('while') & paren_expr & m(';')) |
      (m('{') & statement.repeat & m('}')) |
      (expr & m(';')) |
      m(';')
  end
  rule(:paren_expr) { m('(') & expr & m(')') }
  rule(:expr) { (id & m('=') & expr) | test }
  rule(:test) { (sum & m('<') & sum) | sum }
  rule(:sum) { (term & m(/[+-]/) & sum) | term }
  rule(:term) { paren_expr | id | int }
  rule(:id) { m(/[a-z]/) }
  rule(:int) { m(/[0-9]+/) }
end

TEST_CODE = %(
{
  i = 1;
  while (i < 100) i = i+1;
}
)

parser = TinyCParser.new
parser.parse(TEST_CODE).pretty_print
