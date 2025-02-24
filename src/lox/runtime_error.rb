# src/lox/runtime_error.rb
# frozen_string_literal: true

module Lox
  class RuntimeError < StandardError
    attr_reader :token

    def initialize(token, message)
      super(message)
      @token = token
    end
  end
end
