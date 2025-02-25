# frozen_string_literal: true

require_relative '../interpreter/lox_callable'
require_relative '../interpreter/lox_function'
require_relative '../interpreter/return'
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
          until at_end?
            stmt = statement
            statements << stmt if stmt # Filter nil statements
          end
          statements
        rescue ParseError
          statements.compact # Return non-nil statements we managed to parse
        end
      end

      private

      attr_reader :tokens
      attr_accessor :current

      def statement
        if match(Lox::Lexical::TokenType::IF)
          if_statement
        elsif match(Lox::Lexical::TokenType::PRINT)
          print_statement
        elsif match(Lox::Lexical::TokenType::RETURN)
          return_statement
        elsif match(Lox::Lexical::TokenType::WHILE)
          while_statement
        elsif match(Lox::Lexical::TokenType::FOR)
          for_statement
        elsif match(Lox::Lexical::TokenType::LEFT_BRACE)
          Syntax::Stmt::Block.new(block)
        else
          declaration
        end
      end

      def declaration
        if match(Lexical::TokenType::CLASS)
          class_declaration
        elsif match(Lexical::TokenType::FUN)
          function 'function'
        elsif match(Lox::Lexical::TokenType::VAR)
          var_declaration
        else
          expression_statement
        end
      rescue ParseError
        synchronize
        nil
      end

      def class_declaration
        name = consume(Lox::Lexical::TokenType::IDENTIFIER, 'Expect class name.')

        superclass = nil
        if match(Lox::Lexical::TokenType::LESS)
          consume(Lox::Lexical::TokenType::IDENTIFIER, 'Expect superclass name.')
          superclass = Lox::Syntax::Expr::Variable.new(previous)
        end

        consume(Lox::Lexical::TokenType::LEFT_BRACE, "Expect '{' before class body.")

        methods = []
        methods << function('method') while !check(Lox::Lexical::TokenType::RIGHT_BRACE) && !at_end?

        consume(Lox::Lexical::TokenType::RIGHT_BRACE, "Expect '}' after class body.")
        Lox::Syntax::Stmt::Class.new(name, superclass, methods)
      end

      def function(kind)
        name = consume(Lox::Lexical::TokenType::IDENTIFIER, "Expect #{kind} name.")
        consume(Lexical::TokenType::LEFT_PAREN, "Expect '(' after #{kind} name.")
        parameters = []
        unless check(Lexical::TokenType::RIGHT_PAREN)
          loop do
            error(peek, "Can't have more than 255 parameters.") if parameters.length >= 255
            parameters << consume(Lexical::TokenType::IDENTIFIER, 'Expect parameter name.')
            break unless match(Lexical::TokenType::COMMA)
          end
        end
        consume(Lexical::TokenType::RIGHT_PAREN, "Expect ')' after parameters.")
        consume(Lox::Lexical::TokenType::LEFT_BRACE, "Expect '{' before #{kind} body.")
        body = block
        Lox::Syntax::Stmt::Function.new(name, parameters, body)
      end

      def var_declaration
        name = consume(Lox::Lexical::TokenType::IDENTIFIER, 'Expect variable name.')

        initializer = nil
        if match(Lox::Lexical::TokenType::EQUAL)
          initializer = expression
        else
          error(peek, 'Variable declaration missing initializer') unless check(Lox::Lexical::TokenType::SEMICOLON)
        end

        consume(Lox::Lexical::TokenType::SEMICOLON, "Expect ';' after variable declaration.")
        Syntax::Stmt::Var.new(name, initializer)
      end

      def for_statement
        consume(Lox::Lexical::TokenType::LEFT_PAREN, "Expect '(' after 'for'.")

        initializer = if match(Lox::Lexical::TokenType::SEMICOLON)
                        nil
                      elsif match(Lox::Lexical::TokenType::VAR)
                        var_declaration
                      else
                        expression_statement
                      end

        condition = check(Lox::Lexical::TokenType::SEMICOLON) ? nil : expression
        consume(Lox::Lexical::TokenType::SEMICOLON, "Expect ';' after loop condition.")

        increment = nil
        increment = expression unless check(Lox::Lexical::TokenType::RIGHT_PAREN)

        check(Lox::Lexical::TokenType::RIGHT_PAREN) ? nil : expression
        consume(Lox::Lexical::TokenType::RIGHT_PAREN, "Expect ')' after for clauses.")

        body = statement

        if increment
          body = Lox::Syntax::Stmt::Block.new([
                                                body,
                                                Lox::Syntax::Stmt::Expression.new(increment)
                                              ])
        end

        body = Lox::Syntax::Stmt::While.new(condition || Lox::Syntax::Expr::Literal.new(true), body)
        body = Lox::Syntax::Stmt::Block.new([initializer, body]) if initializer

        body
      end

      def while_statement
        consume(Lox::Lexical::TokenType::LEFT_PAREN, "Expect '(' after 'while'.")
        condition = expression
        consume(Lox::Lexical::TokenType::RIGHT_PAREN, "Expect ')' after condition.")
        body = statement
        Lox::Syntax::Stmt::While.new(condition, body)
      end

      def return_statement
        keyword = previous
        value = check(Lox::Lexical::TokenType::SEMICOLON) ? nil : expression
        consume(Lox::Lexical::TokenType::SEMICOLON, "Expect ';' after return value.")
        Lox::Syntax::Stmt::Return.new(keyword, value)
      end

      def if_statement
        consume(Lox::Lexical::TokenType::LEFT_PAREN, "Expect '(' after 'if'.")
        condition = expression
        consume(Lox::Lexical::TokenType::RIGHT_PAREN, "Expect ')' after if condition.")
        then_branch = statement
        else_branch = match(Lox::Lexical::TokenType::ELSE) ? statement : nil
        Lox::Syntax::Stmt::If.new(condition, then_branch, else_branch)
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
        assignment
      end

      def assignment
        expr = or_
        if match(Lox::Lexical::TokenType::EQUAL)
          equals = previous
          value = assignment # Recurse for chained assignments
          if expr.is_a?(Syntax::Expr::Variable)
            return Syntax::Expr::Assign.new(expr.name, value)
          elsif expr.is_a?(Lox::Syntax::Expr::Get)
            get = expr
            return Lox::Syntax::Expr::Set.new(get.object, get.name, value)
          end

          error(equals, 'Invalid assignment target.')
        end
        expr
      end

      def block
        statements = []
        while !check(Lox::Lexical::TokenType::RIGHT_BRACE) && !at_end?
          stmt = statement
          statements << stmt if stmt
        end
        consume(Lox::Lexical::TokenType::RIGHT_BRACE, "Expect '}' after block.")
        statements
      end

      def or_
        expr = and_
        while match(Lox::Lexical::TokenType::OR)
          operator = previous
          right = and_
          expr = Lox::Syntax::Expr::Logical.new(expr, operator, right)
        end
        expr
      end

      def and_
        expr = equality
        while match(Lox::Lexical::TokenType::AND)
          operator = previous
          right = equality
          expr = Lox::Syntax::Expr::Logical.new(expr, operator, right)
        end
        expr
      end

      def equality
        expr = comparison
        while match(Lox::Lexical::TokenType::BANG_EQUAL, Lox::Lexical::TokenType::EQUAL_EQUAL)
          operator = previous
          right = comparison
          expr = Syntax::Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def comparison
        expr = term
        while match(Lox::Lexical::TokenType::GREATER, Lox::Lexical::TokenType::GREATER_EQUAL,
                    Lox::Lexical::TokenType::LESS, Lox::Lexical::TokenType::LESS_EQUAL)
          operator = previous
          right = term
          expr = Syntax::Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def term
        expr = factor
        while match(Lox::Lexical::TokenType::MINUS, Lox::Lexical::TokenType::PLUS)
          operator = previous
          right = factor
          expr = Syntax::Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def factor
        expr = unary
        while match(Lox::Lexical::TokenType::SLASH, Lox::Lexical::TokenType::STAR)
          operator = previous
          right = unary
          expr = Syntax::Expr::Binary.new(expr, operator, right)
        end
        expr
      end

      def unary
        if match(Lox::Lexical::TokenType::BANG, Lox::Lexical::TokenType::MINUS)
          operator = previous
          right = unary
          return Syntax::Expr::Unary.new(operator, right)
        end
        call
      end

      def call
        expr = primary
        loop do
          if match(Lox::Lexical::TokenType::LEFT_PAREN)
            expr = finish_call(expr)
          elsif match(Lox::Lexical::TokenType::DOT)
            name = consume(Lox::Lexical::TokenType::IDENTIFIER, "Expect property name after '.'.")
            expr = Lox::Syntax::Expr::Get.new(expr, name)
          else
            break
          end
        end
        expr
      end

      def finish_call(callee)
        arguments = []
        unless check(Lox::Lexical::TokenType::RIGHT_PAREN)
          loop do
            error(peek, "Can't have more than 255 arguments.") if arguments.length >= 255
            arguments << expression
            break unless match(Lox::Lexical::TokenType::COMMA)
          end
        end
        paren = consume(Lox::Lexical::TokenType::RIGHT_PAREN, "Expect ')' after arguments.")
        Expr::Call.new(callee, paren, arguments)
      end

      def primary
        if match(Lox::Lexical::TokenType::FALSE)
          return Syntax::Expr::Literal.new(false)
        elsif match(Lox::Lexical::TokenType::TRUE)
          return Syntax::Expr::Literal.new(true)
        elsif match(Lox::Lexical::TokenType::NIL)
          return Syntax::Expr::Literal.new(nil)
        elsif match(Lox::Lexical::TokenType::NUMBER, Lox::Lexical::TokenType::STRING)
          return Syntax::Expr::Literal.new(previous.literal)
        elsif match(Lox::Lexical::TokenType::SUPER)
          keyword = previous
          consume(Lox::Lexical::TokenType::DOT, "Expect '.' after 'super'.")
          method = consume(Lox::Lexical::TokenType::IDENTIFIER, 'Expect superclass method name.')
          return Lox::Syntax::Expr::Super.new(keyword, method)
        elsif match(Lox::Lexical::TokenType::THIS)
          return Syntax::Expr::This.new(previous)
        elsif match(Lox::Lexical::TokenType::IDENTIFIER)
          return Syntax::Expr::Variable.new(previous)
        elsif match(Lox::Lexical::TokenType::LEFT_PAREN)
          expr = expression
          consume(Lox::Lexical::TokenType::RIGHT_PAREN, "Expect ')' after expression.")
          return Syntax::Expr::Grouping.new(expr)
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
