# frozen_string_literal: true

require 'rspec'

require_relative '../src/lox/interpreter/lox_class'
require_relative '../src/lox/interpreter/expression_evaluator'
require_relative '../src/lox/syntax/stmt'
require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'

module Spec
  RSpec.describe Lox::Interpreter::LoxClass do
    # ======================================================================
    # Section: LoxClass Tests
    # Purpose: Contains tests to verify the functionality of LoxClass.
    # ======================================================================

    let(:evaluator) { Lox::Interpreter::ExpressionEvaluator.new }
    let(:class_name) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'MyClass', nil, 1) }
    let(:method_token) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'say', nil, 2) }
    let(:method_stmt) do
      Lox::Syntax::Stmt::Function.new(method_token, [],
                                       [Lox::Syntax::Stmt::Print.new(Lox::Syntax::Expr::Literal.new('Hello'))])
    end
    let(:methods) { { 'say' => Lox::Interpreter::LoxFunction.new(method_stmt, evaluator.globals, false) } }
    let(:klass) { Lox::Interpreter::LoxClass.new('MyClass', nil, methods) }

    it 'instantiates a class with no arguments' do
      instance = klass.call(evaluator, [])
      expect(instance).to be_a(Lox::Interpreter::LoxInstance)
      expect(instance.to_s).to eq('MyClass instance')
    end

    it 'finds a method by name' do
      method = klass.find_method('say')
      expect(method).to be_a(Lox::Interpreter::LoxFunction)
      expect(method.to_s).to eq('<fn say>')
    end

    it 'returns nil for undefined method' do
      expect(klass.find_method('missing')).to be_nil
    end

    it 'reports zero arity for no initializer' do
      expect(klass.arity).to eq(0)
    end
  end
end
