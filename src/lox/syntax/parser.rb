# frozen_string_literal: true

require_relative '../lexical/token'

module Lox
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    private

    attr_reader :tokens
    attr_accessor :current

    
  end
end