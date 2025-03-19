# frozen_string_literal: true

module Lox
  module Interpreter
    class Return < StandardError
      # ======================================================================
      # Section: Return Class
      # Purpose: Contains methods for handling return statements.
      # ======================================================================

      attr_reader :value

      def initialize(value)
        super('Return statement')
        @value = value
      end
    end
  end
end
