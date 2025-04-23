#!/usr/bin/env ruby

require_relative 'visitor'

class AstPrinter < Visitor
  def print(statements)
    statements.map { |statement| statement.accept(self) }.join("\n")
  end

  def visit_assign_expr(expr)
    parentheize(expr.name.lexeme, expr.value)
  end

  def visit_binary_expr(expr)
    parentheize(expr.operator.lexeme, expr.left, expr.right)
  end

  def visit_grouping_expr(expr)
    parentheize("group", expr.expression)
  end

  def visit_literal_expr(expr)
    expr.value&.inspect || 'nil'
  end

  def visit_unary_expr(expr)
    parentheize(expr.operator.lexeme, expr.right)
  end

  def visit_variable_expr(expr)
    expr.name.lexeme
  end

  def visit_block_stmt(stmt)
    parentheize("block", *stmt.statements)
  end

  def visit_expression_stmt(stmt)
    print([stmt.expression])
  end

  def visit_print_stmt(stmt)
    parentheize("print", stmt.expression)
  end

  def visit_var_stmt(stmt)
    parentheize("var #{stmt.name.lexeme}", stmt.initializer)
  end

  private

  def parentheize(name, *exprs)
    "(#{name} #{exprs.map{|expr| expr.accept(self) }.join(' ')})"
  end
end
