# frozen_string_literal: true

require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'
require_relative '../src/lox/syntax/expr'

module Generator
  class AstPrinter
    def print(expr)
      expr.accept(self)
    end

    def visit_binary_expr(expr)
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def visit_grouping_expr(expr)
      parenthesize('group', expr.expression)
    end

    def visit_literal_expr(expr)
      expr.value.nil? ? 'nil' : expr.value.to_s
    end

    def visit_unary_expr(expr)
      parenthesize(expr.operator.lexeme, expr.right)
    end

    private

    def parenthesize(name, *exprs)
      "(#{name} #{exprs.map { |expr| expr.accept(self) }.join(' ')})"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  expression = Lox::Expr::Binary.new(
    Lox::Expr::Unary.new(
      Lox::Lexical::Token.new(Lox::Lexical::TokenType::MINUS, '-', nil, 1),
      Lox::Expr::Literal.new(123)
    ),
    Lox::Lexical::Token.new(Lox::Lexical::TokenType::STAR, '*', nil, 1),
    Lox::Expr::Grouping.new(
      Lox::Expr::Literal.new(45.67)
    )
  )

  printer = Generator::AstPrinter.new
  puts printer.print(expression)
end
