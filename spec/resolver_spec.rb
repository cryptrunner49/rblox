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
    # ======================================================================
    # Section: Resolver Tests
    # Purpose: Contains tests to verify the functionality of the resolver.
    # ======================================================================

    let(:evaluator) { Lox::Interpreter::ExpressionEvaluator.new }
    let(:resolver) { Lox::Interpreter::Resolver.new(evaluator) }
    let(:token) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'x', nil, 1) }

    context 'Variable Resolution' do
      it 'resolves a variable in the global scope' do
        stmt = Lox::Syntax::Stmt::Var.new(token, Lox::Syntax::Expr::Literal.new(42))
        resolver.resolve([stmt])
        expect(evaluator.instance_variable_get(:@locals)).to be_empty
      end

      it 'resolves a variable in a block scope' do
        outer_stmt = Lox::Syntax::Stmt::Var.new(token, Lox::Syntax::Expr::Literal.new(42))
        inner_var = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'y', nil, 2)
        inner_stmt = Lox::Syntax::Stmt::Var.new(inner_var, Lox::Syntax::Expr::Literal.new(100))
        block_stmt = Lox::Syntax::Stmt::Block.new([inner_stmt])
        resolver.resolve([outer_stmt, block_stmt])
        expect(evaluator.instance_variable_get(:@locals)).to be_empty
      end
    end

    context 'Class Resolution' do
      it 'resolves a class with a method' do
        class_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'MyClass', nil, 1)
        method_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'say', nil, 2)
        method_stmt = Lox::Syntax::Stmt::Function.new(method_token, [],
                                                      [Lox::Syntax::Stmt::Print.new(Lox::Syntax::Expr::Literal.new('Hello'))])
        # Add nil for the superclass parameter
        class_stmt = Lox::Syntax::Stmt::Class.new(class_token, nil, [method_stmt])
        resolver.resolve([class_stmt])
        expect { resolver.resolve([class_stmt]) }.not_to raise_error
      end
    end

    context 'Property Resolution' do
      it 'resolves a property set expression' do
        var_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'x', nil, 1)
        prop_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'name', nil, 1)
        value_expr = Lox::Syntax::Expr::Literal.new('test')
        get_expr = Lox::Syntax::Expr::Get.new(Lox::Syntax::Expr::Variable.new(var_token), prop_token)
        set_stmt = Lox::Syntax::Stmt::Expression.new(Lox::Syntax::Expr::Set.new(get_expr.object, get_expr.name,
                                                                                value_expr))
        resolver.resolve([set_stmt])
        expect { resolver.resolve([set_stmt]) }.not_to raise_error
      end
    end
  end
end
