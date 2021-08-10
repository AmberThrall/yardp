# frozen_string_literal: true

require_relative 'nonterminal'

module Yardp
  class Terminal < Nonterminal
    attr_accessor :matches

    def initialize(matches, *flags)
      super(:terminal)
      @matches = Array(matches).flatten
      @case_sensitive = true if flags&.include?(:s) || flags&.include?(:sensitive)
      @case_sensitive = false if flags&.include?(:i) || flags&.include?(:insensitive)
    end

    def to_s
      @matches.map { |m| Util.sanitize_string(m) }.join(', ')
    end

    protected

    def apply_impl(text, pos, opts, _depth)
      pos = strip_whitespace(text, pos, opts)
      return [ParseTree.new(:terminal, ''), pos] if @matches.empty?
      return [ParseTree.new(:terminal, '', [], :failed), -1] if pos >= text.length

      case_sensitive = @case_sensitive
      case_sensitive ||= opts[:case_sensitive]

      @matches.each do |match|
        match = /#{match.source}/i if !case_sensitive && match.is_a?(Regexp)
        match = text[pos..].match(match) if match.is_a?(Regexp)
        next if match.nil?

        if case_sensitive
          next if text[pos..pos + match.to_s.length - 1] != match.to_s && !match.to_s.empty?
        elsif text[pos..pos + match.to_s.length - 1].downcase != match.to_s.downcase && !match.to_s.empty?
          next
        end

        return [ParseTree.new(:terminal, text[pos..pos + match.to_s.length - 1], []), pos + match.to_s.length]
      end

      if @assert
        raise ParseError.new(pos, "Expected #{@matches[0]}", text) if @matches.length == 1

        raise ParseError.new(pos, "Expected #{@matches[..-2].join(', ')} or #{@matches[-1]}", text)
      end

      [ParseTree.new(:terminal, to_s, [], :failed), -1]
    end
  end
end
