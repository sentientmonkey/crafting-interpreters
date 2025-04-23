#!/usr/bin/env ruby

class Visitor
  def visit_literal(expr)
    raise "implement"
  end

  def visit_binary(expr)
    raise "implement"
  end

  def visit_grouping(expr)
    raise "implement"
  end

  def visit_unary(expr)
    raise "implement"
  end
end
