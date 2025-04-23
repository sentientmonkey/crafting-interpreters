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
      if match(:CLASS)
        class_declaration
      elsif match(:FUN)
        function("function")
      elsif match(:VAR)
        var_declaration
      else
        statement
      end
    rescue ParserError
      synchronize
      nil
    end
  end

  def class_declaration
    name = consume(:IDENTIFIER, "Expect class name.")
    consume(:LEFT_BRACE, "Expect '{' before class body.")

    methods = []
    while !check(:RIGHT_BRACE) && !at_end?
      methods << function("method")
    end

    consume(:RIGHT_BRACE, "Expect '}' after class body.")

    Stmt::Class.new(name, methods)
  end

  def statement
    return for_statement if match(:FOR)
    return if_statement if match(:IF)
    return print_statement if match(:PRINT)
    return return_statement if match(:RETURN)
    return while_statement if match(:WHILE)
    return Stmt::Block.new(block) if match(:LEFT_BRACE)

    expression_statement
  end

  def for_statement
    consume(:LEFT_PAREN, "Expect '(' after 'for'.")
    initializer = if match(:SEMICOLON)
                    nil
                  elsif match(:VAR)
                    var_declaration
                  else
                    expression_statement
                  end

    condition = expression if !check(:SEMICOLON)
    consume(:SEMICOLON, "Expect ';' after loop condition.")

    increment = expression if !check(:RIGHT_PAREN)
    consume(:RIGHT_PAREN, "Expect ')' after for clauses.")
    body = statement

    if increment
      body = Stmt::Block.new(
        [body, Stmt::Expression.new(increment)]
      )
    end

    condition = Expr::Literal.new(true) if !condition
    body = Stmt::While.new(condition, body)

    if initializer
      body = Stmt::Block.new(
        [initializer, body]
      )
    end

    body
  end

  def if_statement
    consume(:LEFT_PAREN, "Expect '(' after 'if'.")
    condition = expression
    consume(:RIGHT_PAREN, "Expect ')' after if condition'")

    then_branch = statement
    else_branch = statement if match(:ELSE)

    Stmt::If.new(condition, then_branch, else_branch)
  end

  def print_statement
    value = expression
    consume(:SEMICOLON, "Expect ';' after value.")
    Stmt::Print.new value
  end

  def return_statement
    keyword = previous
    value = nil
    if !check(:SEMICOLON)
      value = expression
    end

    consume(:SEMICOLON, "Expect ';' after return value'")
    Stmt::Return.new(keyword, value)
  end

  def var_declaration
    name = consume(:IDENTIFIER, "Expect variable name.")

    initializer = expression if match(:EQUAL)

    consume(:SEMICOLON, "Expect ';' after declaration.")
    Stmt::Var.new(name, initializer)
  end

  def while_statement
    consume(:LEFT_PAREN, "Expect '(' after 'while'.")
    condition = expression
    consume(:RIGHT_PAREN, "Expect ')' after condition.")
    body = statement

    Stmt::While.new(condition, body)
  end

  def expression_statement
    expr = expression
    consume(:SEMICOLON, "Expect ';' after value.")
    Stmt::Expression.new expr
  end

  def function(kind)
    name = consume(:IDENTIFIER, "Expect #{kind} name")
    consume(:LEFT_PAREN, "Expect '(' after #{kind} name")
    parameters = []
    if !check(:RIGHT_PAREN)
      begin
        if parameters.size >= 255
          error(peek, "Can't have more than 255 parameters.")
        end

        parameters << consume(:IDENTIFIER, "Expect parameter name.")
      end while match(:COMMA)
    end

    consume(:RIGHT_PAREN, "Expect ')' after parameters'.")

    consume(:LEFT_BRACE, "Expect '{' before #{kind} body.")
    body = block
    Stmt::Function.new(name, parameters, body)
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
    expr = or_expr

    if match(:EQUAL)
      equals = previous
      value = assignment

      if expr.is_a?(Expr::Variable)
        name = expr.name
        return Expr::Assign.new(name, value)
      elsif expr.is_a?(Expr::Get)
        get = expr
        return Expr::Set.new(get.object, get.name, value)
      end

      error(equals, "Invalid assignment target.")
    end

    expr
  end

  # or is reserved keyword
  def or_expr
    expr = and_expr
    
    while match(:OR)
      operator = previous
      right = and_expr
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  # and is reserved keyword
  def and_expr
    expr = equality

    while match(:AND)
      operator = previous
      right = equality
      expr = Expr::Logical.new(expr, operator, right)
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
      call
    end
  end

  def call
    expr = primary

    while true
      if match(:LEFT_PAREN)
        expr = finish_call(expr)
      elsif match(:DOT)
        name = consume(:IDENTIFIER,
                       "Expect property name after '.'.")
        expr = Expr::Get.new(expr, name)
      else
        break
      end
    end

    expr
  end

  def finish_call(callee)
    arguments = []

    if !check(:RIGHT_PAREN)
      begin
        if arguments.size >= 255
          error(peek, "Can't have more than 255 arguments.")
        end
        arguments << expression
      end while match(:COMMA)
    end

    paren = consume(:RIGHT_PAREN, "Expect ')' after arguments'")

    Expr::Call.new(callee, paren, arguments)
  end

  def primary
    return Expr::Literal.new(false) if match(:FALSE)
    return Expr::Literal.new(true) if match(:TRUE)
    return Expr::Literal.new(nil) if match(:NIL)

    if match(:NUMBER, :STRING)
      return Expr::Literal.new(previous.literal)
    end

    if match(:THIS)
      return Expr::This.new(previous)
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
