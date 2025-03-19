# frozen_string_literal: true

require 'rspec'

require_relative '../src/lox/lexical/analyzer'
require_relative '../src/lox/syntax/parser'

module Spec
  RSpec.describe Lox::Syntax::Parser do
    # ======================================================================
    # Section: Parser Tests
    # Purpose: Contains tests to verify the functionality of the parser.
    # ======================================================================

    def tokens_for(source)
      analyzer = Lox::Lexical::Analyzer.new(source)
      analyzer.scan_tokens
    end

    it 'parses a simple print statement' do
      source = 'print 123;'
      tokens = tokens_for(source)
      parser = Lox::Syntax::Parser.new(tokens)
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
      parser = Lox::Syntax::Parser.new(tokens)
      statements = parser.parse
      expect(statements).not_to be_empty
    end

    it 'parses a class declaration with methods' do
      source = <<~LOX
        class MyClass {
          say() { print "Hello"; }
        }
      LOX
      tokens = tokens_for(source)
      parser = Lox::Syntax::Parser.new(tokens)
      statements = parser.parse
      expect(statements.size).to eq(1)
      expect(statements[0]).to be_a(Lox::Syntax::Stmt::Class)
      expect(statements[0].methods.size).to eq(1)
      expect(statements[0].methods[0].name.lexeme).to eq('say')
    end

    it 'parses property assignment with get and set' do
      source = 'x.name = "test";'
      tokens = tokens_for(source)
      parser = Lox::Syntax::Parser.new(tokens)
      statements = parser.parse
      expect(statements.size).to eq(1)
      expect(statements[0]).to be_a(Lox::Syntax::Stmt::Expression)
      expect(statements[0].expression).to be_a(Lox::Syntax::Expr::Set)
    end
  end
end
