# frozen_string_literal: true

require_relative 'lox_callable'
require_relative 'environment'

module Lox
  module Interpreter
    class LoxFunction
      include LoxCallable

      def initialize(declaration, closure)
        @declaration = declaration
        @closure = closure
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
          e.value # Return the value from the Return exception
        end
        
        nil
      end
    end
  end
end
