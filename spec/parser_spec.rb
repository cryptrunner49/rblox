# frozen_string_literal: true

# Module: Lox::Syntax
# Tests for parsing basic expressions, nested blocks, and error recovery in the parser.

require 'rspec'
require_relative '../src/lox/lexical/analyzer'
require_relative '../src/lox/syntax/parser'

module Lox
  module Syntax
    RSpec.describe Parser do
      def tokens_for(source)
        analyzer = Lox::Lexical::Analyzer.new(source)
        analyzer.scan_tokens
      end

      it 'parses a simple print statement' do
        source = 'print 123;'
        tokens = tokens_for(source)
        parser = Parser.new(tokens)
        statements = parser.parse
        expect(statements.size).to eq(1)
      end

      it 'parses nested blocks correctly' do
        source = <<~LOX
          {
            print 1;
            {
              print 2;
            }
            print 3;
          }
        LOX
        tokens = tokens_for(source)
        parser = Parser.new(tokens)
        statements = parser.parse
        expect(statements).not_to be_empty
      end
    end
  end
end
