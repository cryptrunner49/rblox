# frozen_string_literal: true

require_relative '../lexical/token'
require_relative '../lexical/token_type'
require_relative 'expr'
require_relative 'stmt'

module Lox
  module Syntax
    class Parser
      class ParseError < StandardError; end

      def initialize(tokens)
        @tokens = tokens
        @current = 0
      end

      def parse
        statements = []
        begin
          statements << statement until at_end?
          statements
        rescue ParseError
          nil
        end
      end

      private

      attr_reader :tokens
      attr_accessor :current

      def statement
        return print_statement if match(Lox::Lexical::TokenType::PRINT)

        expression_statement
      end

      def print_statement
        value = expression
        consume(Lox::Lexical::TokenType::SEMICOLON, "Expect ';' after value.")
        Syntax::Stmt::Print.new(value)
      end

      def expression_statement
        expr = expression
        consume(Lox::Lexical::TokenType::SEMICOLON, "Expect ';' after expression.")
        Syntax::Stmt::Expression.new(expr)
      end

      def expression
        equality
      end

      def equality
        expr = comparison
        while match(Lox::Lexical::TokenType::BANG_EQUAL, Lox::Lexical::TokenType::EQUAL_EQUAL)
          operator = previous
          right = comparison
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def comparison
        expr = term
        while match(Lox::Lexical::TokenType::GREATER, Lox::Lexical::TokenType::GREATER_EQUAL,
                    Lox::Lexical::TokenType::LESS, Lox::Lexical::TokenType::LESS_EQUAL)
          operator = previous
          right = term
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def term
        expr = factor
        while match(Lox::Lexical::TokenType::MINUS, Lox::Lexical::TokenType::PLUS)
          operator = previous
          right = factor
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def factor
        expr = unary
        while match(Lox::Lexical::TokenType::SLASH, Lox::Lexical::TokenType::STAR)
          operator = previous
          right = unary
          expr = Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def unary
        if match(Lox::Lexical::TokenType::BANG, Lox::Lexical::TokenType::MINUS)
          operator = previous
          right = unary
          return Expr::Unary.new(operator, right)
        end
        primary
      end

      def primary
        if match(Lox::Lexical::TokenType::FALSE)
          return Expr::Literal.new(false)
        elsif match(Lox::Lexical::TokenType::TRUE)
          return Expr::Literal.new(true)
        elsif match(Lox::Lexical::TokenType::NIL)
          return Expr::Literal.new(nil)
        elsif match(Lox::Lexical::TokenType::NUMBER, Lox::Lexical::TokenType::STRING)
          return Expr::Literal.new(previous.literal)
        elsif match(Lox::Lexical::TokenType::LEFT_PAREN)
          expr = expression
          consume(Lox::Lexical::TokenType::RIGHT_PAREN, "Expect ')' after expression.")
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
        peek.type == Lox::Lexical::TokenType::EOF
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
        Lox::Runner.error(token, message)
        ParseError.new
      end

      def synchronize
        advance
        until at_end?
          return if previous.type == Lox::Lexical::TokenType::SEMICOLON

          case peek.type
          when Lox::Lexical::TokenType::CLASS, Lox::Lexical::TokenType::FUN,
               Lox::Lexical::TokenType::VAR, Lox::Lexical::TokenType::FOR,
               Lox::Lexical::TokenType::IF, Lox::Lexical::TokenType::WHILE,
               Lox::Lexical::TokenType::PRINT, Lox::Lexical::TokenType::RETURN
            return
          end
          advance
        end
      end
    end
  end
end
