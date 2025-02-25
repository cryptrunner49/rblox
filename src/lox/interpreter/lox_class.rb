# frozen_string_literal: true

require_relative 'lox_instance'
require_relative 'lox_callable'
require_relative 'lox_function'

module Lox
  module Interpreter
    class LoxClass
      include Lox::Interpreter::LoxCallable

      def initialize(name, methods = {})
        @name = name
        @methods = methods
      end

      def find_method(name)
        @methods[name] if @methods.key?(name)
      end

      def call(interpreter, arguments)
        instance = Lox::Interpreter::LoxInstance.new(self)  # Creates a new instance of this class

        initializer = find_method("init")
        if initializer
          initializer.bind(instance).call(interpreter, arguments)
        end

        return instance
      end

      def arity
        initializer = find_method("init")
        return 0 unless initializer
        initializer.arity
      end      

      def to_s
        @name
      end

      private

      attr_reader :name, :methods
    end
  end
end