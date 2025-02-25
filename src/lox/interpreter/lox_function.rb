# frozen_string_literal: true

require_relative 'lox_callable'
require_relative 'environment'

module Lox
  module Interpreter
    class LoxFunction
      include Lox::Interpreter::LoxCallable

      def initialize(declaration, closure, is_initializer)
        @is_initializer = is_initializer
        @declaration = declaration
        @closure = closure
      end

      def bind(instance)
        environment = Lox::Interpreter::Environment.new(@closure)
        environment.define('this', instance)
        LoxFunction.new(@declaration, environment, @is_initializer)
      end

      def to_s
        "<fn #{@declaration.name.lexeme}>"
      end

      def arity
        @declaration.parameters.length
      end

      def call(interpreter, arguments)
        environment = Lox::Interpreter::Environment.new(@closure)
        @declaration.parameters.each_with_index do |param, i|
          environment.define(param.lexeme, arguments[i])
        end
        begin
          interpreter.execute_block(@declaration.body, environment)
          nil # Default return value if no return statement
        rescue Lox::Interpreter::Return => e
          return closure.get_at(0, 'this') if @is_initializer

          e.value # Return the value from the Return exception
        end

        return closure[0, 'this'] if @is_initializer

        nil
      end
    end
  end
end
