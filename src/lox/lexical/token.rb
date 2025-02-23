# frozen_string_literal: true

module Lox
  module Lexical
    class Token
      attr_reader :type, :lexeme, :literal, :line

      def initialize(type, lexeme, literal, line)
        @type = type.freeze
        @lexeme = lexeme.freeze
        @literal = literal.freeze
        @line = line
      end

      def to_s
        "#{type} #{lexeme} #{literal}"
      end
    end
  end
end