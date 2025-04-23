#!/usr/bin/env ruby

# These are primarly for documentation since ruby doesn't have
# interfaces.

module ExprVisitor
  def visit_assign_expr(expr)
    raise "implement"
  end

  def visit_binary_expr(expr)
    raise "implement"
  end

  def visit_grouping_expr(expr)
    raise "implement"
  end

  def visit_literal_expr(expr)
    raise "implement"
  end

  def visit_unary_expr(expr)
    raise "implement"
  end

  def visit_variable_expr(expr)
    raise "implement"
  end
end

module StmtVisitor
  def visit_block_stmt(stmt)
    raise "implement"
  end

  def visit_expression_stmt(stmt)
    raise "implement"
  end

  def visit_print_stmt(stmt)
    raise "implement"
  end

  def visit_var_stmt(stmt)
    raise "implement"
  end
end

class Visitor
  include ExprVisitor
  include StmtVisitor
end
