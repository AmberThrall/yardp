# frozen_string_literal: true

require_relative '../lib/yardp'

class PostalAddress < Yardp::Grammar
  start('postal-address')
  option(:strip_whitespace, false)

  abnf(<<-END)
    postal-address   = name-part street zip-part
    name-part        = *(personal-part SP) last-name [SP suffix] CRLF
    name-part        =/ personal-part CRLF
    personal-part    = first-name / (initial ".")
    first-name       = *ALPHA
    initial          = ALPHA
    last-name        = *ALPHA
    suffix           = ("Jr." / "Sr." / 1*("I" / "V" / "X"))
    street           = house-num SP street-name CRLF
    house-num        = 1*8(DIGIT / ALPHA)
    street-name      = 1*(VCHAR) *(SP 1*VCHAR)
    zip-part         = town-name "," SP state 1*2SP zip-code CRLF
    town-name        = 1*(ALPHA / SP)
    state            = 2ALPHA
    zip-code         = 5DIGIT ["-" 4DIGIT]
  END
end

grammar = PostalAddress.new
grammar.graphviz.output(png: 'postal-address-grammar.png')
tree = grammar.parse("Amber Thrall\r\n1064 E Lowell St\r\nTucson, AZ 85719\r\n")
tree.graphviz.output(png: 'postal-address.png')
tree.pretty_print
