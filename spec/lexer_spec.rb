# frozen_string_literal: true

# Module: Lox::Lexical
# Tests for tokenization and edge cases in the lexical analyzer.

require 'rspec'
require_relative '../src/lox/lexical/analyzer'
require_relative '../src/lox/lexical/token_type'

module Lox
  module Lexical
    RSpec.describe Analyzer do
      it 'scans tokens for a simple print statement with a string literal' do
        source = 'print "Hello";'
        analyzer = Analyzer.new(source)
        tokens = analyzer.scan_tokens
        token_types = tokens.map(&:type)
        expect(token_types).to include(TokenType::PRINT, TokenType::STRING, TokenType::SEMICOLON)
      end

      it 'scans tokens for nested blocks' do
        source = '{ var x = 5; }'
        analyzer = Analyzer.new(source)
        tokens = analyzer.scan_tokens
        token_types = tokens.map(&:type)
        expect(token_types).to include(TokenType::LEFT_BRACE, TokenType::VAR, TokenType::IDENTIFIER, TokenType::NUMBER,
                                       TokenType::RIGHT_BRACE)
      end
    end
  end
end
