# frozen_string_literal: true

require 'rspec'
require 'stringio'
require_relative '../src/lox/interpreter/lox_function'
require_relative '../src/lox/interpreter/expression_evaluator'
require_relative '../src/lox/syntax/stmt'
require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'

module Spec
    RSpec.describe Lox::Interpreter::LoxFunction do
      let(:evaluator) { Lox::Interpreter::ExpressionEvaluator.new }
      let(:token) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "test", nil, 1) }
      let(:param) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "a", nil, 1) }
      let(:print_stmt) { Lox::Syntax::Stmt::Print.new(Lox::Syntax::Expr::Variable.new(param)) }
      let(:stmt) { Lox::Syntax::Stmt::Function.new(token, [param], [print_stmt]) }
      let(:function) { Lox::Interpreter::LoxFunction.new(stmt, evaluator.globals, false) }  # Add false for is_initializer

      def capture_stdout
        original_stdout = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original_stdout
      end

      it 'executes a function with a parameter' do
        evaluator.interpret([stmt])
        call_expr = Lox::Syntax::Expr::Call.new(
          Lox::Syntax::Expr::Variable.new(token),
          Lox::Lexical::Token.new(Lox::Lexical::TokenType::RIGHT_PAREN, ")", nil, 1),
          [Lox::Syntax::Expr::Literal.new("Hello")]
        )
        output = capture_stdout { evaluator.evaluate(call_expr) }
        expect(output).to eq("Hello\n")
      end

      it 'returns the correct arity' do
        expect(function.arity).to eq(1)
      end
    end
end