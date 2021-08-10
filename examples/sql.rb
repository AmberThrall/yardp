# frozen_string_literal: true

require_relative '../lib/yardp'

# A simplified SQL grammar modified from Database Systems - The Complete Book (2nd Edition)
class SQLParser < Yardp::Grammar
  start(:query)

  token(:SELECT, 'SELECT')
  token(:FROM, 'FROM')
  token(:WHERE, 'WHERE')
  token(:AND, 'AND')
  token(:OR, 'OR')
  token(:IN, 'IN')
  token(:LIKE, 'LIKE')
  token(:IDENTIFIER, /[A-Za-z_][A-Za-z_0-9]*/)
  token(:ESCAPE_CODE, /\\(?:u[0-9A-Fa-f]{4}|c.|C-.|M-\\C-.|[0-7]+|.)/)
  token(:OPERATOR, ['=', '<>', '!=', '>', '>=', '<', '<='])

  rule(:query) { SELECT >> sellist >> FROM >> fromlist >> WHERE >> condition }
  rule(:sellist) { attribute >> (t(',') >> attribute).repeat }
  rule(:fromlist) { relation >> (t(',') >> relation).repeat }
  rule(:condition) do
    attribute >> (
      (IN >> t('(') >> query >> t(')')) |
      (OPERATOR >> attribute) |
      (LIKE >> pattern)
    ) >> repeat((AND | OR) >> condition)
  end
  rule(:attribute) { t('*') | IDENTIFIER >> maybe(t('.') >> attribute) }
  rule(:relation) { IDENTIFIER }
  rule(:pattern, split_whitespace: false) { t('\'') >> character.repeat >> t('\'') }
  rule(:character) { ESCAPE_CODE | t(/[^\\']/) }
end

QUERY = %(
  SELECT movieTitle
  FROM StarsIn, MovieStar
  WHERE starName = name
    AND birthdate LIKE '%1960'
)

SQLParser.new.parse(QUERY).graphviz.output(png: 'sql.png')
