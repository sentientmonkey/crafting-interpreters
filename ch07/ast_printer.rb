#!/usr/bin/env ruby

require_relative 'visitor'

class AstPrinter < Visitor
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
    expr.value&.to_s || 'nil'
  end

  def visit_unary(expr)
    parentheize(expr.operator.lexeme, expr.right)
  end

  private

  def parentheize(name, *exprs)
    "(#{name} #{exprs.map{|expr| expr.accept(self) }.join(' ')})"
  end
end
