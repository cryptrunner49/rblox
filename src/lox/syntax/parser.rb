# frozen_string_literal: true

require_relative '../lexical/token'
require_relative '../lexical/token_type'
require_relative 'expr'

module Lox
  module Syntax
    class Parser
      class ParseError < StandardError; end

      def initialize(tokens)
        @tokens = tokens
        @current = 0
      end

      def parse
        expression
      rescue ParseError
        nil
      end

      private

      attr_reader :tokens
      attr_accessor :current

      def expression
        equality
      end

      def equality
        expr = comparison
        while match(Lexical::TokenType::BANG_EQUAL, Lexical::TokenType::EQUAL_EQUAL)
          operator = previous
          right = comparison
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def comparison
        expr = term
        while match(Lexical::TokenType::GREATER, Lexical::TokenType::GREATER_EQUAL,
                    Lexical::TokenType::LESS, Lexical::TokenType::LESS_EQUAL)
          operator = previous
          right = term
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def term
        expr = factor
        while match(Lexical::TokenType::MINUS, Lexical::TokenType::PLUS)
          operator = previous
          right = factor
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def factor
        expr = unary
        while match(Lexical::TokenType::SLASH, Lexical::TokenType::STAR)
          operator = previous
          right = unary
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def unary
        if match(Lexical::TokenType::BANG, Lexical::TokenType::MINUS)
          operator = previous
          right = unary
          return Expr::Unary.new(operator, right)
        end
        primary
      end

      def primary
        if match(Lexical::TokenType::FALSE)
          return Expr::Literal.new(false)
        elsif match(Lexical::TokenType::TRUE)
          return Expr::Literal.new(true)
        elsif match(Lexical::TokenType::NIL)
          return Expr::Literal.new(nil)
        elsif match(Lexical::TokenType::NUMBER, Lexical::TokenType::STRING)
          return Expr::Literal.new(previous.literal)
        elsif match(Lexical::TokenType::LEFT_PAREN)
          expr = expression
          consume(Lexical::TokenType::RIGHT_PAREN, "Expect ')' after expression.")
          return Expr::Grouping.new(expr)
        end

        raise error(peek, 'Expect expression.')
      end

      def match(*types)
        types.each do |type|
          if check(type)
            advance
            return true
          end
        end
        false
      end

      def check(type)
        return false if at_end?

        peek.type == type
      end

      def advance
        self.current += 1 unless at_end?
        previous
      end

      def at_end?
        peek.type == Lexical::TokenType::EOF
      end

      def peek
        tokens[current]
      end

      def previous
        tokens[current - 1]
      end

      def consume(type, message)
        return advance if check(type)

        raise error(peek, message)
      end

      def error(token, message)
        Lox::Interpreter.error(token, message)
        ParseError.new
      end

      def synchronize
        advance
        until at_end?
          return if previous.type == Lexical::TokenType::SEMICOLON

          case peek.type
          when Lexical::TokenType::CLASS, Lexical::TokenType::FUN, Lexical::TokenType::VAR, Lexical::TokenType::FOR,
              Lexical::TokenType::IF, Lexical::TokenType::WHILE, Lexical::TokenType::PRINT, Lexical::TokenType::RETURN
            return
          end
          advance
        end
      end
    end
  end
end
