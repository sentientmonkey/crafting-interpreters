#!/usr/bin/env ruby

require_relative 'visitor'
require_relative 'lox_runtime_error'

class Interpreter < Visitor
  def interpret(expression)
    begin
      value = evaluate(expression)
      puts stringify(value)
    rescue LoxRuntimeError => e
      Lox.runtime_error(e)
    end
  end

  def visit_literal(expr)
    expr.value
  end

  def visit_binary(expr)
    left = evaluate(expr.left)
    right = evaluate(expr.right)

    case expr.operator.type
    when :GREATER
      check_number_operands!(expr.operator, left, right)
      left > right
    when :GREATER_EQUAL
      check_number_operands!(expr.operator, left, right)
      left >= right
    when :LESS
      check_number_operands!(expr.operator, left, right)
      left < right
    when :LESS_EQUAL
      check_number_operands!(expr.operator, left, right)
      left <= right
    when :MINUS
      check_number_operands!(expr.operator, left, right)
      left - right
    when :PLUS
      if (left.is_a?(Numeric) && right.is_a?(Numeric)) ||
          (left.is_a?(String) && right.is_a?(String))
        left + right
      else
        raise LoxRuntimeError.new(
          expr.operator,
          "Operands must be two numbers or two strings."
        )
      end
    when :SLASH
      check_number_operands!(expr.operator, left, right)
      left / right
    when :STAR
      check_number_operands!(expr.operator, left, right)
      left * right
    when :BANG_EQUAL
      !equal?(left, right)
    when :EQUAL_EQUAL
      equal?(left, right)
    end
  end

  def visit_grouping(expr)
    evaluate(expr.expression)
  end

  def visit_unary(expr)
    right = evaluate(expr.right)

    case expr.operator.type
    when :MINUS
      -right
    when :BANG
      !truthy?(right)
    end
  end

  private

  def evaluate(expr)
    expr.accept(self)
  end

  # not really needed in ruby, but we'll follow along
  def truthy?(object)
    return false if object.nil?
    return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)

    true # i hate this. why are things true by default?
  end

  # not really needed in ruby, but we'll follow along
  def equal?(a, b)
    return true if a.nil? && b.nil?
    return false if a.nil?

    a == b
  end

  def stringify(object)
    return 'nil' if object.nil?

    if object.is_a?(Numeric)
      text = object.to_s
      text.gsub!(/\.0$/, '')
      return text
    end

    object.to_s
  end

  # unused?
  def check_number_operand!(operator, operand)
    return if operand.is_a?(Numeric)
    raise LoxRuntimeError.new(operand, "Operand must be a number")
  end

  def check_number_operands!(operator, left, right)
    return if left.is_a?(Numeric) && right.is_a?(Numeric)
    raise LoxRuntimeError.new(operator, "Operands must be numbers")
  end
end
