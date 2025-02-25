# frozen_string_literal: true

# Module: Lox::Lexical
# Tests for tokenization and edge cases in the lexical analyzer.

require 'rspec'

require_relative '../src/lox/lexical/analyzer'
require_relative '../src/lox/lexical/token_type'

module Spec
  RSpec.describe Lox::Lexical::Analyzer do
    it 'scans tokens for a simple print statement with a string literal' do
      source = 'print "Hello";'
      analyzer = Lox::Lexical::Analyzer.new(source)
      tokens = analyzer.scan_tokens
      token_types = tokens.map(&:type)
      expect(token_types).to include(Lox::Lexical::TokenType::PRINT, Lox::Lexical::TokenType::STRING,
                                     Lox::Lexical::TokenType::SEMICOLON)
    end

    it 'scans tokens for nested blocks' do
      source = '{ var x = 5; }'
      analyzer = Lox::Lexical::Analyzer.new(source)
      tokens = analyzer.scan_tokens
      token_types = tokens.map(&:type)
      expect(token_types).to include(Lox::Lexical::TokenType::LEFT_BRACE, Lox::Lexical::TokenType::VAR, Lox::Lexical::TokenType::IDENTIFIER, Lox::Lexical::TokenType::NUMBER,
                                     Lox::Lexical::TokenType::RIGHT_BRACE)
    end
  end
end
