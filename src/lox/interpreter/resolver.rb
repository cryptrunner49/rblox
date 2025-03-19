# frozen_string_literal: true

require_relative 'expression_evaluator'
require_relative '../syntax/expr'
require_relative '../syntax/stmt'

module Lox
  module Interpreter
    class Resolver
      # ======================================================================
      # Section: Resolver Class
      # Purpose: Contains methods for resolving variable references.
      # ======================================================================

      FUNCTION_TYPES = {
        none: :none,
        function: :function,
        initializer: :initializer,
        method: :method
      }.freeze
      CLASS_TYPES = {
        none: :none,
        class: :class,
        subclass: :subclass
      }.freeze

      # The interpreter is used to associate resolved variables with their scopes.
      def initialize(interpreter)
        raise ArgumentError, 'Interpreter cannot be nil' unless interpreter

        @interpreter = interpreter
        @environment = interpreter.globals
        @locals = {}
        @scopes = [] # Each scope is a Hash mapping variable names (String) to Boolean
        @current_function = :none # Using symbols for enum-like behavior
        @current_class = :none
      end

      # Statement visitor methods

      def visit_block_stmt(stmt)
        begin_scope
        resolve(stmt.statements)
        end_scope
        nil
      end

      def resolve(statements)
        statements.each { |stmt| resolve_stmt(stmt) }
      end

      def resolve_stmt(stmt)
        stmt.accept(self)
      end

      def resolve_expr(expr)
        expr.accept(self)
      end

      def begin_scope
        @scopes.push({})
      end

      def end_scope
        @scopes.pop
      end

      def visit_var_stmt(stmt)
        declare(stmt.name)
        resolve_expr(stmt.initializer) unless stmt.initializer.nil?
        define(stmt.name)
        nil
      end

      def declare(token)
        return if @scopes.empty?

        scope = @scopes.last
        Lox::Runner.error(name, 'Already variable with this name in this scope.') if scope.key?(token.lexeme)

        # Mark the variable as "declared but not defined"
        scope[token.lexeme] = false
      end

      def define(token)
        return if @scopes.empty?

        @scopes.last[token.lexeme] = true
      end

      def visit_variable_expr(expr)
        if !@scopes.empty? &&
           @scopes.last.key?(expr.name.lexeme) &&
           @scopes.last[expr.name.lexeme] == false
          Lox.error(expr.name, "Can't read local variable in its own initializer.")
        end
        resolve_local(expr, expr.name)
        nil
      end

      def resolve_local(expr, token)
        # Search scopes from innermost (last) to outermost (first)
        @scopes.reverse.each_with_index do |scope, i|
          next unless scope.key?(token.lexeme)

          # Pass the distance (number of scopes between current and the one containing the variable)
          @interpreter.resolve(expr, i)
          return
        end
      end

      def visit_assign_expr(expr)
        resolve_expr(expr.value)
        resolve_local(expr, expr.name)
        nil
      end

      def visit_function_stmt(stmt)
        declare(stmt.name)
        define(stmt.name)
        resolve_function(stmt, FUNCTION_TYPES[:function])
        nil
      end

      def visit_class_stmt(stmt)
        enclosing_class = @current_class
        @current_class = :class

        declare(stmt.name)
        define(stmt.name)

        if stmt.superclass && stmt.name.lexeme == stmt.superclass.name.lexeme
          Lox::Runner.error(stmt.superclass.name, "A class can't inherit from itself.")
        end

        if stmt.superclass
          @current_class = :subclass
          resolve_expr(stmt.superclass)
        end

        if stmt.superclass
          begin_scope
          @scopes.last['super'] = true
        end

        begin_scope
        @scopes.last['this'] = true

        stmt.methods.each do |method|
          declaration = FUNCTION_TYPES[:method]
          declaration = :initializer if method.name.lexeme.equal?('init')
          resolve_function(method, declaration)
        end

        end_scope

        end_scope if stmt.superclass

        @current_class = enclosing_class
        nil
      end

      def resolve_function(function, type)
        enclosing_function = @current_function
        @current_function = type

        begin_scope
        function.parameters.each do |param|
          declare(param)
          define(param)
        end
        resolve(function.body)
        end_scope

        @current_function = enclosing_function
      end

      def visit_expression_stmt(stmt)
        resolve_expr(stmt.expression)
        nil
      end

      def visit_if_stmt(stmt)
        resolve_expr(stmt.condition)
        resolve_stmt(stmt.then_branch)
        resolve_stmt(stmt.else_branch) unless stmt.else_branch.nil?
        nil
      end

      def visit_print_stmt(stmt)
        resolve_expr(stmt.expression)
        nil
      end

      def visit_return_stmt(stmt)
        if @current_function == FUNCTION_TYPES[:none]
          Lox::Runner.error(stmt.keyword, "Can't return from top-level code.")
        end
        Lox.error(stmt.keyword, "Can't return a value from an initializer.") if @current_function == :initializer

        resolve_expr(stmt.value) unless stmt.value.nil?
        nil
      end

      def visit_while_stmt(stmt)
        resolve_expr(stmt.condition)
        resolve_stmt(stmt.body)
        nil
      end

      # Expression visitor methods

      def visit_binary_expr(expr)
        resolve_expr(expr.left)
        resolve_expr(expr.right)
        nil
      end

      def visit_call_expr(expr)
        resolve_expr(expr.callee)
        expr.arguments.each { |argument| resolve_expr(argument) }
        nil
      end

      def visit_get_expr(expr)
        resolve_expr(expr.object)
        nil
      end

      def visit_grouping_expr(expr)
        resolve_expr(expr.expression)
        nil
      end

      def visit_literal_expr(_expr)
        nil
      end

      def visit_logical_expr(expr)
        resolve_expr(expr.left)
        resolve_expr(expr.right)
        nil
      end

      def visit_set_expr(expr)
        resolve_expr(expr.value)
        resolve_expr(expr.object)
        nil
      end

      def visit_super_expr(expr)
        if @current_class == :none
          Lox::Runner.error(expr.keyword, "Can't use 'super' outside of a class.")
        elsif @current_class != :subclass
          Lox::Runner.error(expr.keyword, "Can't use 'super' in a class with no superclass.")
        end

        resolve_local(expr, expr.keyword)
        nil
      end

      def visit_this_expr(expr)
        if @current_class == :none
          # Replace the Lox.error call with an exception
          raise Lox::Interpreter::RuntimeError.new(
            expr.keyword,
            "Can't use 'this' outside of a class."
          )
        end

        resolve_local(expr, expr.keyword)
        nil
      end

      def visit_unary_expr(expr)
        resolve_expr(expr.right)
        nil
      end
    end
  end
end
