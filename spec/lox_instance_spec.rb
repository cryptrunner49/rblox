# frozen_string_literal: true

require 'rspec'
require 'stringio'

require_relative '../src/lox/interpreter/lox_instance'
require_relative '../src/lox/interpreter/lox_class'
require_relative '../src/lox/interpreter/lox_function'
require_relative '../src/lox/interpreter/expression_evaluator'
require_relative '../src/lox/syntax/stmt'
require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'

module Spec
    RSpec.describe Lox::Interpreter::LoxInstance do
      let(:evaluator) { Lox::Interpreter::ExpressionEvaluator.new }
      let(:class_name) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "MyClass", nil, 1) }
      let(:method_token) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "say", nil, 1) }
      let(:method_stmt) { Lox::Syntax::Stmt::Function.new(method_token, [], [Lox::Syntax::Stmt::Print.new(Lox::Syntax::Expr::Literal.new("Hello"))]) }
      let(:methods) { { "say" => Lox::Interpreter::LoxFunction.new(method_stmt, evaluator.globals, false) } }
      let(:klass) { Lox::Interpreter::LoxClass.new("MyClass", methods) }
      let(:instance) { Lox::Interpreter::LoxInstance.new(klass) }

      def capture_stdout
        original_stdout = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original_stdout
      end

      it 'sets and gets a property' do
        prop_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "name", nil, 1)
        instance.set(prop_token, "test")
        expect(instance.get(prop_token)).to eq("test")
      end

      it 'raises error for undefined property' do
        prop_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "missing", nil, 1)
        expect { instance.get(prop_token) }.to raise_error(Lox::Interpreter::RuntimeError, "Undefined property 'missing'.")
      end

      it 'retrieves a method from the class' do
        method = instance.get(method_token)
        expect(method).to be_a(Lox::Interpreter::LoxFunction)
        output = capture_stdout { method.call(evaluator, []) }
        expect(output).to eq("Hello\n")
      end
    end
end