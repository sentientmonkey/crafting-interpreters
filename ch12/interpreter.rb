#!/usr/bin/env ruby

require_relative 'visitor'
require_relative 'environment'
require_relative 'lox_runtime_error'
require_relative 'lox_callable'
require_relative 'lox_class'
require_relative 'lox_function'
require_relative 'return'

class Interpreter < Visitor
  def initialize
    @globals = Environment.new
    @environment = @globals
    @locals = {}

    @globals.define("clock", Class.new do
      include LoxCallable

      def arity = 0

      def call(interpreter, arguments)
        Time.now.to_i
      end

      def to_s
        "<native fn>"
      end
    end.new)
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

  def visit_logical_expr(expr)
    left = evaluate(expr.left)

    if expr.operator.type == :OR
      return left if truthy?(left)
    else
      return left if !truthy?(left)
    end

    evaluate(expr.right)
  end

  def visit_set_expr(expr)
    object = evaluate(expr.object)

    if !object.is_a?(LoxInstance)
      raise LoxRuntimeError(
        expr.name,
        "Only instances have fields."
      )
    end

    value = evaluate(expr.value)
    object.set(expr.name, value)

    value
  end

  def visit_this_expr(expr)
    lookup_variable(expr.keyword, expr)
  end

  def visit_assign_expr(expr)
    value = evaluate(expr.value)

    distance = @locals[expr]
    if !distance.nil?
      @environment.assign_at(distance, expr.name, value)
    else
      @globals.assign(expr.name, value)
    end

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

  def visit_call_expr(expr)
    callee = evaluate(expr.callee)

    arguments = []
    expr.arguments.each do |argument|
      arguments << evaluate(argument)
    end

    if !callee.class.include?(LoxCallable)
      raise LoxRuntimeError.new(
        expr.paren,
        "Can only call functions and classes."
      )
    end
    function = callee

    if arguments.size != function.arity
      raise LoxRuntimeError.new(
        expr.paren,
        "Expected #{function.arity} arguments but got #{arguments.size}.",
      )
    end

    function.call(self, arguments)
  end

  def visit_get_expr(expr)
    object = evaluate(expr.object)
    if !object.is_a?(LoxInstance)
      raise LoxRuntimeError.new(
        expr.name,
        "Only instances have properties."
      )
    end

    object.get(expr.name)
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
    lookup_variable(expr.name, expr)
  end

  def lookup_variable(name, expr)
    distance = @locals[expr]
    if !distance.nil?
      @environment.get_at(distance, name.lexeme)
    else
      @globals.get(name)
    end
  end

  def visit_block_stmt(stmt)
    execute_block(stmt.statements, Environment.new(@environment))
    nil
  end

  def visit_class_stmt(stmt)
    @environment.define(stmt.name.lexeme, nil)

    methods = {}
    stmt.methods.each do |method|
      function = LoxFunction.new(
        method,
        @environment,
        method.name.lexeme == 'init',
      )
      methods[method.name.lexeme] = function
    end

    klass = LoxClass.new(stmt.name.lexeme, methods)
    @environment.assign(stmt.name, klass)

    nil
  end

  def visit_expression_stmt(stmt)
    evaluate stmt.expression
    nil
  end

  def visit_function_stmt(stmt)
    function = LoxFunction.new(stmt, @environment, false)
    @environment.define(stmt.name.lexeme, function)
    nil
  end

  def visit_if_stmt(stmt)
    if truthy?(evaluate(stmt.condition))
      execute stmt.then_branch
    elsif stmt.else_branch
      execute stmt.else_branch
    end
    nil
  end

  def visit_print_stmt(stmt)
    value = evaluate stmt.expression
    puts stringify(value)
    nil
  end

  def visit_return_stmt(stmt)
    value = nil
    if stmt.value != nil
      value = evaluate(stmt.value)
    end

    raise Return.new(value)
  end

  def visit_var_stmt(stmt)
    value = evaluate(stmt.initializer) unless stmt.initializer.nil?

    @environment.define(stmt.name.lexeme, value)
    nil
  end

  def visit_while_stmt(stmt)
    while truthy?(evaluate(stmt.condition))
      execute(stmt.body)
    end
    nil
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

  def resolve(expr, depth)
    @locals[expr] = depth
  end

  private

  def evaluate(expr)
    expr.accept(self)
  end

  def execute(stmt)
    stmt.accept(self)
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
