# frozen_string_literal: true

require_relative 'runtime_error'

module Lox
  module Interpreter
    class Environment
      def initialize(enclosing = nil)
        @enclosing = enclosing
        @values = {}
      end

      def define(name, value)
        @values[name] = value
      end

      def get(name)
        return @values[name.lexeme] if @values.key?(name.lexeme)
        return @enclosing.get(name) if @enclosing

        raise Lox::RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end

      def assign(name, value)
        if @values.key?(name.lexeme)
          @values[name.lexeme] = value
          return
        end
        if @enclosing
          @enclosing.assign(name, value)
          return
        end
        raise Lox::RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end
  end
end
