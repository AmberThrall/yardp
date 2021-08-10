# frozen_string_literal: true

require_relative '../lib/yardp'

class EnglishParser < Yardp::Parser
  start(:sentence)

  rule(:sentence) { subject >> verb_phrase >> object >> punctuation }
  rule(:punctuation) { m('.') | m('!') | m('?') }
  rule(:subject) { m('This') | m('Ruby') | m('I') }
  rule(:verb_phrase) { (adverb >> verb) | verb }
  rule(:adverb) { m('never') }
  rule(:verb) { m('is') | m('run') | m('am') | m('tell') }
  rule(:object) { (m('the') >> noun) | (m('a') >> noun) | noun }
  rule(:noun) { m('university') | m('awesome') | m('cheese') | m('lies') }
end

parser = EnglishParser.new
parser.parse('Ruby is awesome!').pretty_print
