#!/usr/bin/env ruby

require_relative 'expr'
require_relative 'stmt'

class Parser
  class ParserError < StandardError; end

  def initialize(tokens)
    @tokens = tokens
    @current = 0
  end

  def parse
    statements = []
    while !at_end?
      statements << declaration
    end
    statements
  end

  private

  def expression
    assignment
  end

  def declaration
    begin
      if match(:VAR)
        var_declaration
      else
        statement
      end
    rescue ParserError
      synchronize
      nil
    end
  end

  def statement
    return print_statement if match(:PRINT)
    return Stmt::Block.new(block) if match(:LEFT_BRACE)

    expression_statement
  end

  def print_statement
    value = expression
    consume(:SEMICOLON, "Expect ';' after value.")
    Stmt::Print.new value
  end

  def var_declaration
    name = consume(:IDENTIFIER, "Expect variable name.")

    initializer = expression if match(:EQUAL)

    consume(:SEMICOLON, "Expect ';' after declaration.")
    Stmt::Var.new(name, initializer)
  end

  def expression_statement
    expr = expression
    consume(:SEMICOLON, "Expect ';' after value.")
    Stmt::Expression.new expr
  end

  def block
    statements = []

    while !check(:RIGHT_BRACE) && !at_end?
      statements << declaration
    end

    consume(:RIGHT_BRACE, "Expect '}' after block.")
    statements
  end

  def assignment
    expr = equality

    if match(:EQUAL)
      equals = previous
      value = assignment

      if expr.is_a?(Expr::Variable)
        name = expr.name
        return Expr::Assign.new(name, value)
      end

      error(equals, "Invalid assignment target.")
    end

    expr
  end

  def equality
    expr = comparison
    while match(:BANG_EQUAL, :EQUAL_EQUAL)
      operator = previous
      right = comparison
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def comparison
    expr = term
    while match(:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL)
      operator = previous
      right = term
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def term
    expr = factor

    while match(:MINUS, :PLUS)
      operator = previous
      right = factor
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def factor
    expr = unary

    while match(:SLASH, :STAR)
      operator = previous
      right = unary
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def unary
    if match(:BANG, :MINUS)
      operator = previous
      right = unary
      Expr::Unary.new(operator, right)
    else
      primary
    end
  end

  def primary
    return Expr::Literal.new(false) if match(:FALSE)
    return Expr::Literal.new(true) if match(:TRUE)
    return Expr::Literal.new(nil) if match(:NIL)

    if match(:NUMBER, :STRING)
      return Expr::Literal.new(previous.literal)
    end

    if match(:IDENTIFIER)
      return Expr::Variable.new(previous)
    end

    if match(:LEFT_PAREN)
      expr = expression
      consume(:RIGHT_PAREN, "Expect ')' after expression.")
      return Expr::Grouping.new(expr)
    end

    raise error(peek, "Expect expression.")
  end

  def match(*types)
    types.each do |type|
      if check(type)
        advance
        return true
      end
    end

    false
  end

  def consume(type, message)
    if check(type)
      return advance
    end

    raise error(peek, message)
  end

  def error(token, message)
    Lox.error(token, message)
    ParserError.new
  end

  def synchronize
    advance

    while !at_end?
      return if previous.type == :SEMICOLON

      if [:CLASS,
       :FUN,
       :VAR,
       :FOR,
       :IF,
       :WHILE,
       :PRINT,
       :RETURN].include?(peek.type)
        return
      end

      advance
    end
  end

  def check(type)
    return false if at_end?
    peek.type == type
  end

  def advance
    if !at_end?
      @current += 1
    end

    previous
  end

  def at_end?
    peek.type == :EOF
  end

  def peek
    @tokens[@current]
  end

  def previous
    @tokens[@current-1]
  end
end
