# frozen_string_literal: true

require 'rspec'
require 'stringio'

require_relative '../src/lox/interpreter/expression_evaluator'
require_relative '../src/lox/syntax/expr'
require_relative '../src/lox/syntax/stmt'
require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'

module Spec
    RSpec.describe Lox::Interpreter::ExpressionEvaluator do
      let(:evaluator) { Lox::Interpreter::ExpressionEvaluator.new }

      def capture_stdout
        original_stdout = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original_stdout
      end

      context 'Expression Evaluation' do
        it 'evaluates a literal expression' do
          expr = Lox::Syntax::Expr::Literal.new(42)
          expect(evaluator.evaluate(expr)).to eq(42)
        end

        it 'evaluates a binary addition expression' do
          left = Lox::Syntax::Expr::Literal.new(2)
          right = Lox::Syntax::Expr::Literal.new(3)
          operator = Lox::Lexical::Token.new(Lox::Lexical::TokenType::PLUS, '+', nil, 1)
          expr = Lox::Syntax::Expr::Binary.new(left, operator, right)
          expect(evaluator.evaluate(expr)).to eq(5)
        end
      end

      context 'Statement Execution' do
        it 'executes a print statement' do
          expr = Lox::Syntax::Expr::Literal.new("Hello")
          stmt = Lox::Syntax::Stmt::Print.new(expr)
          output = capture_stdout { evaluator.execute(stmt) }
          expect(output).to eq("Hello\n")
        end

        it 'handles variable declaration and lookup' do
          name = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "x", nil, 1)
          initializer = Lox::Syntax::Expr::Literal.new(10)
          var_stmt = Lox::Syntax::Stmt::Var.new(name, initializer)
          evaluator.execute(var_stmt)

          var_expr = Lox::Syntax::Expr::Variable.new(name)
          expect(evaluator.evaluate(var_expr)).to eq(10)
        end

        it 'executes class instantiation and property setting' do
          class_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "MyClass", nil, 1)
          class_stmt = Lox::Syntax::Stmt::Class.new(class_token, [])
          var_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "x", nil, 1)
          call_expr = Lox::Syntax::Expr::Call.new(Lox::Syntax::Expr::Variable.new(class_token), Lox::Lexical::Token.new(Lox::Lexical::TokenType::RIGHT_PAREN, ")", nil, 1), [])
          var_stmt = Lox::Syntax::Stmt::Var.new(var_token, call_expr)
          prop_token = Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, "name", nil, 1)
          set_stmt = Lox::Syntax::Stmt::Expression.new(Lox::Syntax::Expr::Set.new(Lox::Syntax::Expr::Variable.new(var_token), prop_token, Lox::Syntax::Expr::Literal.new("test")))
          get_expr = Lox::Syntax::Expr::Get.new(Lox::Syntax::Expr::Variable.new(var_token), prop_token)
          print_stmt = Lox::Syntax::Stmt::Print.new(get_expr)

          output = capture_stdout { evaluator.interpret([class_stmt, var_stmt, set_stmt, print_stmt]) }
          expect(output).to eq("test\n")
        end
      end
    end
end