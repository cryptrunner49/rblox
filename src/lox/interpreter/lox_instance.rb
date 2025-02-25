# frozen_string_literal: true

module Lox
  module Interpreter
    class LoxInstance

      def initialize(klass)
        @klass = klass
        @fields = {}
      end

      def get(name)
        if @fields.key?(name.lexeme)
          @fields[name.lexeme]
        else
          method = @klass.find_method(name.lexeme)
          return method.bind(self) if method
          raise Lox::Interpreter::RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
        end
      end

      def set(name, value)
        @fields[name.lexeme] = value
      end

      def to_s
        "#{@klass} instance"
      end
    end
  end
end