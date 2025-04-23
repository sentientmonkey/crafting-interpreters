#!/usr/bin/env ruby

class AstPrinter
  def print(expr)
    expr.accept(self)
  end

  def visit_binary(expr)
    parentheize(expr.operator.lexeme, expr.left, expr.right)
  end

  def visit_grouping(expr)
    parentheize("group", expr.expression)
  end

  def visit_literal(expr)
    return 'nil' if expr.nil?
    expr.value.to_s
  end

  def visit_unary(expr)
    parentheize(expr.operator.lexeme, expr.right)
  end

  def parentheize(name, *exprs)
    "(#{name} #{exprs.map{|expr| expr.accept(self) }.join(' ')})"
  end
end
