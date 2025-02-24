# frozen_string_literal: true

require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'
require_relative '../src/lox/syntax/expr'

module Generator
  class AstPrinter
    def print(node)
      return unless node

      node.accept(self)
    end

    # Expr Visitor Methods
    def visit_assign_expr(expr)
      parenthesize("= #{expr.name.lexeme}", expr.value)
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

    def visit_call_expr(expr)
      args = expr.arguments.map { |arg| arg.accept(self) }.join(' ')
      "(call #{expr.callee.accept(self)} #{args})"
    end

    def visit_variable_expr(expr)
      expr.name.lexeme
    end

    # Stmt Visitor Methods
    def visit_block_stmt(stmt)
      statements_str = stmt.statements.map { |s| s.accept(self) }.join(' ')
      "(block #{statements_str})"
    end

    def visit_expression_stmt(stmt)
      stmt.expression.accept(self) # Delegate to the expression's printing
    end

    def visit_print_stmt(stmt)
      parenthesize('print', stmt.expression)
    end

    def visit_var_stmt(stmt)
      if stmt.initializer
        parenthesize("var #{stmt.name.lexeme}", stmt.initializer)
      else
        "(var #{stmt.name.lexeme})"
      end
    end

    private

    def parenthesize(name, *nodes)
      "(#{name} #{nodes.map { |node| node.accept(self) }.join(' ')})"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  # Test Expr
  expression = Lox::Syntax::Expr::Binary.new(
    Lox::Syntax::Expr::Unary.new(
      Lox::Lexical::Token.new(Lox::Lexical::TokenType::MINUS, '-', nil, 1),
      Lox::Syntax::Expr::Literal.new(123)
    ),
    Lox::Lexical::Token.new(Lox::Lexical::TokenType::STAR, '*', nil, 1),
    Lox::Syntax::Expr::Grouping.new(
      Lox::Syntax::Expr::Literal.new(45.67)
    )
  )

  printer = Generator::AstPrinter.new
  puts printer.print(expression)

  # Test Stmt
  stmt = Lox::Stmt::Print.new(
    Lox::Syntax::Expr::Literal.new('Hello')
  )
  puts printer.print(stmt)

  var_stmt = Lox::Stmt::Var.new(
    Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'x', nil, 1),
    Lox::Syntax::Expr::Literal.new(42)
  )
  puts printer.print(var_stmt)

  block_stmt = Lox::Stmt::Block.new([
                                      Lox::Stmt::Expression.new(Lox::Syntax::Expr::Literal.new(1)),
                                      Lox::Stmt::Print.new(Lox::Syntax::Expr::Literal.new('test'))
                                    ])
  puts printer.print(block_stmt)
end
