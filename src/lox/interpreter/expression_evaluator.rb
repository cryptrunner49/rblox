# frozen_string_literal: true

require_relative '../syntax/expr'
require_relative '../syntax/stmt'
require_relative '../lexical/token_type'
require_relative 'environment'

module Lox
  module Interpreter
    class ExpressionEvaluator
      def initialize
        @environment = Interpreter::Environment.new
      end

      def interpret(statements)
        statements.each do |statement|
          execute(statement)
        end
      rescue Lox::RuntimeError => e
        Lox::Runner.runtime_error(e)
        nil # Return nil to indicate failure
      end

      # Expr Visitor Methods
      def visit_literal_expr(expr)
        expr.value
      end

      def visit_grouping_expr(expr)
        evaluate(expr.expression)
      end

      def visit_unary_expr(expr)
        right = evaluate(expr.right)
        case expr.operator.type
        when Lox::Lexical::TokenType::BANG
          !is_truthy(right)
        when Lox::Lexical::TokenType::MINUS
          check_number_operand(expr.operator, right)
          -right.to_f
        else
          nil # Unreachable
        end
      end

      def visit_binary_expr(expr)
        left = evaluate(expr.left)
        right = evaluate(expr.right)
        case expr.operator.type
        when Lox::Lexical::TokenType::GREATER
          check_number_operands(expr.operator, left, right)
          left.to_f > right.to_f
        when Lox::Lexical::TokenType::GREATER_EQUAL
          check_number_operands(expr.operator, left, right)
          left.to_f >= right.to_f
        when Lox::Lexical::TokenType::LESS
          check_number_operands(expr.operator, left, right)
          left.to_f < right.to_f
        when Lox::Lexical::TokenType::LESS_EQUAL
          check_number_operands(expr.operator, left, right)
          left.to_f <= right.to_f
        when Lox::Lexical::TokenType::BANG_EQUAL
          !is_equal(left, right)
        when Lox::Lexical::TokenType::EQUAL_EQUAL
          is_equal(left, right)
        when Lox::Lexical::TokenType::MINUS
          check_number_operands(expr.operator, left, right)
          left.to_f - right.to_f
        when Lox::Lexical::TokenType::PLUS
          if left.is_a?(Numeric) && right.is_a?(Numeric)
            left + right
          elsif left.is_a?(String) && right.is_a?(String)
            left + right
          else
            raise Lox::RuntimeError.new(expr.operator, 'Operands must be two numbers or two strings.')
          end
        when Lox::Lexical::TokenType::SLASH
          check_number_operands(expr.operator, left, right)
          left.to_f / right
        when Lox::Lexical::TokenType::STAR
          check_number_operands(expr.operator, left, right)
          left.to_f * right.to_f
        else
          nil # Unreachable
        end
      end

      def visit_variable_expr(expr)
        @environment.get(expr.name)
      end

      def visit_assign_expr(expr)
        value = evaluate(expr.value)
        @environment.assign(expr.name, value)
        value
      end

      # Stmt Visitor Methods
      def visit_expression_stmt(stmt)
        evaluate(stmt.expression) # No output, just evaluation
        nil
      end

      def visit_print_stmt(stmt)
        value = evaluate(stmt.expression)
        puts stringify(value) # Ensure this prints to stdout
        nil
      end

      def visit_var_stmt(stmt)
        value = stmt.initializer ? evaluate(stmt.initializer) : nil
        @environment.define(stmt.name.lexeme, value)
        nil
      end

      def visit_block_stmt(stmt)
        execute_block(stmt.statements, Lox::Environment.new(@environment))
        nil
      end

      private

      def evaluate(expr)
        expr.accept(self)
      end

      def execute(stmt)
        stmt.accept(self)
      end

      def execute_block(statements, environment)
        previous = @environment
        begin
          @environment = environment
          statements.each { |statement| execute(statement) }
        ensure
          @environment = previous
        end
      end

      def is_truthy(object)
        return false if object.nil?
        return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)

        true
      end

      def is_equal(a, b)
        return true if a.nil? && b.nil?
        return false if a.nil?

        a == b
      end

      def check_number_operand(operator, operand)
        return if operand.is_a?(Numeric)

        raise Lox::RuntimeError.new(operator, 'Operand must be a number.')
      end

      def check_number_operands(operator, left, right)
        return if left.is_a?(Numeric) && right.is_a?(Numeric)

        raise Lox::RuntimeError.new(operator, 'Operands must be numbers.')
      end

      def stringify(object)
        return 'nil' if object.nil?

        if object.is_a?(Float)
          text = object.to_s
          text = text.sub(/\.0$/, '') if text.end_with?('.0')
          return text
        end
        object.to_s
      end
    end
  end
end
