# frozen_string_literal: true

module Lox
  module Interpreter
    class Return < StandardError
      attr_reader :value

      def initialize(value)
        super('Return statement')
        @value = value
      end
    end
  end
end
