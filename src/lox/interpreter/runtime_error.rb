# frozen_string_literal: true

module Lox
  module Interpreter
    class RuntimeError < StandardError
      # ======================================================================
      # Section: RuntimeError Class
      # Purpose: Contains methods for handling runtime errors.
      # ======================================================================

      attr_reader :token

      def initialize(token, message)
        super(message)
        @token = token
      end
    end
  end
end
