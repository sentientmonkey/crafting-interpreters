#!/usr/bin/env ruby

require_relative 'visitor'
require_relative 'environment'
require_relative 'lox_runtime_error'

class Interpreter < Visitor
  def initialize
    @environment = Environment.new
  end

  def interpret(statements)
    begin
      statements.each do |statement|
        execute statement
      end
    rescue LoxRuntimeError => e
      Lox.runtime_error(e)
    end
  end

  def visit_literal_expr(expr)
    expr.value
  end

  def visit_assign_expr(expr)
    value = evaluate(expr.value)
    @environment.assign(expr.name, value)
    value
  end

  def visit_binary_expr(expr)
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

  def visit_grouping_expr(expr)
    evaluate(expr.expression)
  end

  def visit_unary_expr(expr)
    right = evaluate(expr.right)

    case expr.operator.type
    when :MINUS
      -right
    when :BANG
      !truthy?(right)
    end
  end

  def visit_variable_expr(expr)
    @environment.get(expr.name)
  end

  def visit_block_stmt(stmt)
    execute_block(stmt.statements, Environment.new(@environment))
    nil
  end

  def visit_expression_stmt(stmt)
    evaluate stmt.expression
    nil
  end

  def visit_print_stmt(stmt)
    value = evaluate stmt.expression
    puts stringify(value)
    nil
  end

  def visit_var_stmt(stmt)
    value = evaluate(stmt.initializer) unless stmt.initializer.nil?

    @environment.define(stmt.name, value)
    nil
  end

  private

  def evaluate(expr)
    expr.accept(self)
  end

  def execute(stmt)
    stmt.accept(self)
  end

  def execute_block(statements, environment)
    previous = @environment
    begin
      @environment = environment

      statements.each do |statement|
        execute(statement)
      end
    ensure
      @environment = previous
    end
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
