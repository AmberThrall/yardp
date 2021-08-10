# frozen_string_literal: true

require_relative '../yardp'

module Yardp
  module NonterminalMethods
    def terminal(arg, *flags)
      case arg
      when Regexp, String, Array then Terminal.new(arg, *flags)
      else raise Error, 'Invalid argument in \'t\'.'
      end
    end

    def terminal!(arg, *flags)
      terminal(arg, *flags).assert
    end

    def terminal?(arg, *flags)
      terminal(arg, *flags).maybe
    end

    def t(arg, *flags)
      terminal(arg, *flags)
    end

    def t!(arg, *flags)
      terminal!(arg, *flags)
    end

    def t?(arg, *flags)
      terminal?(arg, *flags)
    end

    def maybe(arg)
      return arg.maybe if arg.is_a?(Nonterminal)

      terminal?(arg)
    end

    def repeat(arg, min = 0, max = -1)
      return arg.repeat(min, max) if arg.is_a?(Nonterminal)

      terminal(arg).repeat(min, max)
    end

    def repeat!(arg, min = 0, max = -1)
      repeat(arg, min, max).assert
    end

    def eos
      Eos.new
    end

    def eos!
      eos.assert
    end

    def eos?
      eos.maybe
    end

    def eol
      Eol.new
    end

    def eol!
      eol.assert
    end

    def eol?
      eol.maybe
    end
  end
end
