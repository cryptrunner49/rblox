# frozen_string_literal: true

require 'rspec'

require_relative '../src/lox/interpreter/resolver'
require_relative '../src/lox/interpreter/expression_evaluator'
require_relative '../src/lox/syntax/expr'
require_relative '../src/lox/syntax/stmt'
require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'

module Spec
    RSpec.describe Lox::Interpreter::Resolver do
      let(:evaluator) { Lox::Interpreter::ExpressionEvaluator.new }
      let(:resolver) { Lox::Interpreter::Resolver.new(evaluator) }
      let(:token) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "x", nil, 1) }

      context 'Variable Resolution' do
        it 'resolves a variable in the global scope' do
          stmt = Lox::Syntax::Stmt::Var.new(token, Lox::Syntax::Expr::Literal.new(42))
          resolver.resolve([stmt])
          expect(evaluator.instance_variable_get(:@locals)).to be_empty  # Global vars not in @locals
        end

        it 'resolves a variable in a block scope' do
          outer_stmt = Lox::Syntax::Stmt::Var.new(token, Lox::Syntax::Expr::Literal.new(42))
          inner_var = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "y", nil, 2)
          inner_stmt = Lox::Syntax::Stmt::Var.new(inner_var, Lox::Syntax::Expr::Literal.new(100))
          block_stmt = Lox::Syntax::Stmt::Block.new([inner_stmt])
          resolver.resolve([outer_stmt, block_stmt])
          expect(evaluator.instance_variable_get(:@locals)).to be_empty  # Only local lookups stored
        end
      end
    end
end