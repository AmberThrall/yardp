# frozen_string_literal: true

module Yardp
  class ParseError < StandardError
    attr_reader :pos, :text

    def initialize(pos, msg, text)
      @pos = pos
      @text = text
      super("#{msg} at #{pos}.")
    end
  end
end
