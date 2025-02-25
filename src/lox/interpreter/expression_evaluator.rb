# frozen_string_literal: true

require_relative '../syntax/expr'
require_relative '../syntax/stmt'
require_relative '../lexical/token_type'
require_relative 'environment'
require_relative 'resolver'

module Lox
  module Interpreter
    class ExpressionEvaluator
      # Class-level variable
      GLOBALS = Lox::Interpreter::Environment.new.freeze

      attr_reader :globals

      # Instance variable
      def initialize
        @locals = {}
        @environment = GLOBALS
        @globals = GLOBALS

        @environment.define('clock', Class.new do
          include Lox::Interpreter::LoxCallable

          def arity
            0
          end

          def call(_interpreter, _arguments)
            Time.now.to_f # Returns current time in seconds since epoch
          end

          def to_s
            '<native fn>'
          end
        end.new)
      end

      def interpret(statements)
        resolver = Lox::Interpreter::Resolver.new(self)
        resolver.resolve(statements)
        begin
          statements.each do |statement|
            execute(statement)
          end
        rescue Lox::Interpreter::RuntimeError => e
          Lox::Runner.runtime_error(e)
          nil # Return nil to indicate failure
        end
      end

      # Expr Visitor Methods
      def visit_literal_expr(expr)
        expr.value
      end

      def visit_grouping_expr(expr)
        evaluate(expr.expression)
      end

      # Stmt Visitor Method
      def visit_logical_expr(expr)
        left = evaluate(expr.left)
        if expr.operator.type == Lox::Lexical::TokenType::OR
          return left if is_truthy(left)
        else # AND
          return left unless is_truthy(left)
        end
        evaluate(expr.right)
      end

      def visit_while_stmt(stmt)
        execute(stmt.body) while is_truthy(evaluate(stmt.condition))
        nil
      end

      def visit_if_stmt(stmt)
        if is_truthy(evaluate(stmt.condition))
          execute(stmt.then_branch)
        elsif stmt.else_branch
          execute(stmt.else_branch)
        end
        nil
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

      def visit_call_expr(expr)
        callee = evaluate(expr.callee)
        arguments = expr.arguments.map { |argument| evaluate(argument) }

        unless callee.is_a?(Lox::Interpreter::LoxCallable)
          raise Lox::Interpreter::RuntimeError.new(expr.paren, 'Can only call functions and classes.')
        end

        function = callee

        if arguments.length != function.arity
          raise Lox::Interpreter::RuntimeError.new(expr.paren,
                                                   "Expected #{function.arity} arguments but got #{arguments.length}.")
        end

        function.call(self, arguments)
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
            raise Lox::Interpreter::RuntimeError.new(expr.operator, 'Operands must be two numbers or two strings.')
          end
        when Lox::Lexical::TokenType::SLASH
          check_number_operands(expr.operator, left, right)
          raise Lox::Interpreter::RuntimeError.new(expr.operator, 'Division by zero.') if right.zero?

          left.to_f / right
        when Lox::Lexical::TokenType::STAR
          check_number_operands(expr.operator, left, right)
          left.to_f * right.to_f
        else
          nil # Unreachable
        end
      end

      def visit_variable_expr(expr)
        look_up_variable(expr.name, expr)
      end

      def visit_assign_expr(expr)
        value = evaluate(expr.value)

        distance = @locals[expr]
        if distance
          @environment.assign_at(distance, expr.name, value)
        else
          @interpreter.globals.assign(expr.name, value)
        end

        value
      end

      def visit_expression_stmt(stmt)
        evaluate(stmt.expression)
        nil
      end

      def visit_function_stmt(stmt)
        function = Lox::Interpreter::LoxFunction.new(stmt, @environment)
        @environment.define(stmt.name.lexeme, function)
        nil
      end

      def visit_print_stmt(stmt)
        value = evaluate(stmt.expression)
        puts stringify(value)
        nil
      end

      def visit_return_stmt(stmt)
        value = stmt.value ? evaluate(stmt.value) : nil
        raise Lox::Interpreter::Return, value
      end

      def visit_var_stmt(stmt)
        value = stmt.initializer ? evaluate(stmt.initializer) : nil
        @environment.define(stmt.name.lexeme, value)
        nil
      end

      def visit_block_stmt(stmt)
        execute_block(stmt.statements, Lox::Interpreter::Environment.new(@environment))
        nil
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

      def resolve(expr, depth)
        @locals[expr] = depth
      end

      def evaluate(expr)
        expr.accept(self)
      end

      def execute(stmt)
        stmt.accept(self)
      end

      private

      def look_up_variable(name, expr)
        distance = @locals[expr]
        if distance
          @environment.get_at(distance, name.lexeme)
        else
          @globals.get(name)
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

        raise Lox::Interpreter::RuntimeError.new(operator, 'Operand must be a number.')
      end

      def check_number_operands(operator, left, right)
        return if left.is_a?(Numeric) && right.is_a?(Numeric)

        raise Lox::Interpreter::RuntimeError.new(operator, 'Operands must be numbers.')
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
