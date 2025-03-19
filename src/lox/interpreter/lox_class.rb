# frozen_string_literal: true

require_relative 'lox_instance'
require_relative 'lox_callable'
require_relative 'lox_function'

module Lox
  module Interpreter
    class LoxClass
      # ======================================================================
      # Section: LoxClass Class
      # Purpose: Contains methods for defining and managing Lox classes.
      # ======================================================================

      include Lox::Interpreter::LoxCallable

      def initialize(name, superclass, methods = {})
        @name = name
        @superclass = superclass
        @methods = methods
      end

      def find_method(name)
        # Ensure @methods is a hash and check for the method
        if @methods.is_a?(Hash) && @methods.key?(name)
          @methods[name]
        elsif @superclass
          @superclass.find_method(name)
        end
      end

      def call(interpreter, arguments)
        instance = Lox::Interpreter::LoxInstance.new(self) # Creates a new instance of this class

        initializer = find_method('init')
        initializer&.bind(instance)&.call(interpreter, arguments)

        instance
      end

      def arity
        initializer = find_method('init')
        initializer ? initializer.arity : 0
      end

      def to_s
        @name
      end

      private

      attr_reader :name, :superclass, :methods
    end
  end
end
