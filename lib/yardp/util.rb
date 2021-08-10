# frozen_string_literal: true

module Yardp
  module Util
    def self.sanitize_string(string, pos = 0, max_length = -1)
      return "/#{string.source}/" if string.is_a?(Regexp)
      return string if string[0] == '/' && string[-1] == '/'
      return string if string[0] == '"' && string[-1] == '"'

      string = string[pos..pos + (max_length.negative? ? -1 : max_length - 1)]
      string = "#{string}..." unless max_length.negative? || string.length < max_length
      string = "...#{string}" unless pos.zero? || string.empty?
      string = string.gsub("\n", '\\n')
      string = string.gsub("\r", '\\r')
      string = string.gsub("\t", '\\t')
      string = string.gsub("\v", '\\v')
      string = string.gsub("\f", '\\f')
      string = string.gsub(/\\?"/, "\\\"")
      "\"#{string}\""
    end
  end
end
