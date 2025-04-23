#!/usr/bin/env ruby

require_relative 'token_type'
require_relative 'token'

class Scanner
  KEYWORDS = {
    'and' => :AND,
    'class' => :CLASS,
    'else' => :ELSE,
    'false' => :FALSE,
    'for' => :FOR,
    'fun' => :FUN,
    'if' => :IF,
    'nil' => :NIL,
    'or' => :OR,
    'print' => :PRINT,
    'return' => :RETURN,
    'super' => :SUPER,
    'this' => :THIS,
    'true' => :TRUE,
    'var' => :VAR,
    'while' => :WHILE,
  }
  def initialize source
    @source = source
    @tokens = []
    @start = 0
    @current = 0
    @line = 1
  end

  def scan_tokens
    until at_end?
      @start = @current
      scan_token
    end
    @tokens << Token.new(:EOF, '', nil, @line)
    @tokens
  end

  def scan_token
    c = advance
    case c
    when '(' then add_token :LEFT_PAREN
    when ')' then add_token :RIGHT_PAREN
    when '{' then add_token :LEFT_BRACE
    when '}' then add_token :RIGHT_BRACE
    when ',' then add_token :COMMA
    when '.' then add_token :DOT
    when '-' then add_token :MINUS
    when '+' then add_token :PLUS
    when ';' then add_token :SEMICOLON
    when '*' then add_token :STAR
    when '!' 
      add_token(match('=') ? :BANG_EQUAL : :BANG)
    when '='
      add_token(match('=') ? :EQUAL_EQUAL : :EQUAL)
    when '<'
      add_token(match('=') ? :LESS_EQUAL : :LESS)
    when '>'
      add_token(match('=') ? :GREATER_EQUAL : :GREATER)
    when '/'
      if match '/'
        advance while peek != "\n" && !at_end?
      else
        add_token :SLASH
      end
    when nil
    when ' '
    when "\l"
    when "\r"
    when "\t"
    when "\n"
      @line += 1
    when '"'
      string
    else
      if is_digit? c
        number
      elsif is_alpha? c
        identifier
      else
        Lox.error @line, "Unexpected character: #{c}"
      end
    end
  end

  def identifier
    advance while is_alpha_numeric?(peek)

    text = @source.slice(@start..@current-1)
    type = KEYWORDS.fetch(text) { :IDENTIFIER }

    add_token type
  end

  def number
    advance while is_digit?(peek)

    if peek == '.' && is_digit?(peek_next)
      # consume the "."
      advance

      advance while is_digit?(peek)
    end

    value = @source.slice(@start..@current).to_f
    add_token :NUMBER, value
  end

  def string
    while peek != '"' && !at_end?
      @line += 1 if peek == "\n"
      advance
    end

    if at_end?
      Lox.error @line, "Unterminated string."
    end

    # the closing "
    advance

    value = @source.slice((@start + 1)..(@current-2))
    add_token :STRING, value
  end

  def advance
    c = @source.chars[@current]
    @current += 1
    c
  end

  def match expected
    return false if at_end?
    return false if @source.chars[@current] != expected

    @current += 1
    true
  end

  def peek
    return '' if at_end?
    @source.chars[@current]
  end

  def peek_next
    return '' if @current.succ >= @source.size

    @source.chars[@current+1]
  end

  def is_digit? c
    c && c >= '0' && c <= '9'
  end

  def is_alpha? c
    c && ((c >= 'a' && c <= 'z') ||
          (c >= 'A' && c <= 'Z') ||
          (c == '_'))
  end

  def is_alpha_numeric? c
    is_alpha?(c) || is_digit?(c)
  end

  def add_token type, literal = nil
    # had to update this logic when adding strings...
    text = literal || @source.slice(@start..@current-1)
    @tokens << Token.new(type, text, literal, @line)
  end

  def at_end?
    @current > @source.size
  end
end
