#!/usr/bin/env ruby

require_relative 'expr'

class Parser
  class ParserError < StandardError; end

  def initialize(tokens)
    @tokens = tokens
    @current = 0
  end

  def parse
    begin
      expression
    rescue ParserError
    end
  end

  private

  def expression
    equality
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

  # this is unused at the moment
  def synchronize
    advance

    while !is_at_end?
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
    return false if is_at_end?
    peek.type == type
  end

  def advance
    if !is_at_end?
      @current += 1
    end

    previous
  end

  def is_at_end?
    peek.type == :EOF
  end

  def peek
    @tokens[@current]
  end

  def previous
    @tokens[@current-1]
  end
end
