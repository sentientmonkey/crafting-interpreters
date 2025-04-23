#!/usr/bin/env ruby

require_relative 'visitor'

class Resolver < Visitor

  def initialize(interpreter)
    @interpreter = interpreter
    @scopes = []
    @current_function = :NONE
  end

  def resolve(statements)
    statements.each do |statement|
      resolve_stmt(statement)
    end
  end

  def visit_block_stmt(stmt)
    begin_scope
    resolve(stmt.statements)
    end_scope

    nil
  end

  def visit_var_stmt(stmt)
    declare(stmt.name)
    if !stmt.initializer.nil?
      resolve_expr(stmt.initializer)
    end
    define(stmt.name)

    nil
  end

  def visit_variable_expr(expr)
    if !@scopes.empty? &&
        @scopes.last[expr.name.lexeme] == false
      Lox.error(
        expr.name,
        "Can't read local variable in its own initializer."
      )
    end

    resolve_local(expr, expr.name)

    nil
  end

  def visit_assign_expr(expr)
    resolve_expr(expr.value)
    resolve_local(expr, expr.name)

    nil
  end

  def visit_function_stmt(stmt)
    declare(stmt.name)
    define(stmt.name)

    resolve_function(stmt, :FUNCTION)
    nil
  end

  def visit_expression_stmt(stmt)
    resolve_stmt(stmt.expression)
    nil
  end

  def visit_if_stmt(stmt)
    resolve_expr(stmt.condition)
    resolve_stmt(stmt.then_branch)
    if !stmt.else_branch.nil?
      resolve_stmt(stmt.else_branch)
    end

    nil
  end

  def visit_return_stmt(stmt)
    if @current_function == :NONE
      Lox.error(
        stmt.keyword,
        "Can't return from top-level code.",
      )
    end

    if !stmt.value.nil?
      resolve_stmt(stmt.value)
    end

    nil
  end

  def visit_while_stmt(stmt)
    resolve_expr(stmt.condition)
    resolve_stmt(stmt.body)

    nil
  end

  def visit_binary_expr(expr)
    resolve_expr(expr.left)
    resolve_expr(expr.right)

    nil
  end

  def visit_call_expr(expr)
    resolve_expr(expr.callee)

    expr.arguments.each do |argument|
      resolve_expr(argument)
    end

    nil
  end

  def visit_grouping_expr(expr)
    resolve_expr(expr.expression)

    nil
  end

  def visit_literal_expr(_)
    nil
  end

  def visit_logical_expr(expr)
    resolve_expr(expr.left)
    resolve_expr(expr.right)

    nil
  end

  def visit_unary_expr(expr)
    resolve_expr(expr.right)

    nil
  end

  def visit_print_stmt(stmt)
    resolve_expr(stmt.expression)

    nil
  end

  private

  def begin_scope
    @scopes << {}
  end

  def end_scope
    @scopes.pop
  end

  def declare(name)
    return if @scopes.empty?

    scope = @scopes.last
    if scope.key?(name.lexeme)
      Lox.error(
        name,
        "Already a variable with this name in this scope."
      )
    end
 
    scope[name.lexeme] = false
  end

  def define(name)
    return if @scopes.empty?

    @scopes.last[name.lexeme] = true
  end

  def resolve_local(expr, name)
    (@scopes.size-1).downto(0).each do |i|
      if @scopes[i].key?(name.lexeme)
        @interpreter.resolve(expr, @scopes.size - 1 - i)
        return
      end
    end
  end

  def resolve_stmt(stmt)
    stmt.accept(self)
  end

  def resolve_expr(expr)
    expr.accept(self)
  end

  def resolve_function(function, type)
    enclosing_function = @current_function
    @current_function = type

    begin_scope
    function.params.each do |param|
      declare(param)
      define(param)
    end
    resolve(function.body)
    end_scope
    @current_function = enclosing_function
  end
end
