# frozen_string_literal: true

module Lox
  module Interpreter
    module LoxCallable
      def arity
        raise NotImplementedError, "Classes including LoxCallable must implement 'arity'"
      end

      def call(interpreter, arguments)
        raise NotImplementedError, "Classes including LoxCallable must implement 'call(interpreter, arguments)'"
      end
    end
  end
end
