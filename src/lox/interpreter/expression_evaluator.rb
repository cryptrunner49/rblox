# frozen_string_literal: true

require_relative '../syntax/expr'
require_relative '../lexical/token_type'

module Lox
  module Interpreter
    class ExpressionEvaluator
      def interpret(expression)
        value = evaluate(expression)
        puts stringify(value)
      rescue Lox::RuntimeError => e
        Lox::Runner.runtime_error(e)
      end

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

      def visit_print_stmt(stmt)
        value = evaluate(stmt.expression)
        puts stringify(value)
        nil
      end

      def visit_expression_stmt(stmt)
        evaluate(stmt.expression)
        nil
      end

      private

      def evaluate(expr)
        expr.accept(self)
      end

      def is_truthy(object)
        return false if object.nil?
        return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)

        true
      end

      def is_equal(a, b)
        if a.nil? && b.nil?
          true
        elsif a.nil?
          false
        else
          a == b
        end
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
