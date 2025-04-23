#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'

require_relative 'lox'
require_relative 'scanner'

class ScannerTest < Minitest::Test
  def assert_token expected_token, source
    scanner = Scanner.new source
    assert_equal [expected_token, :EOF], scanner.scan_tokens.map(&:type)
  end

  def test_can_scan_simple_tokens
    scanner = Scanner.new '(){},.-+;*'

    actual = scanner.scan_tokens.map(&:type)
    expected = [
      :LEFT_PAREN,
      :RIGHT_PAREN,
      :LEFT_BRACE,
      :RIGHT_BRACE,
      :COMMA,
      :DOT,
      :MINUS,
      :PLUS,
      :SEMICOLON,
      :STAR,
      :EOF
    ]
    assert_equal expected, actual
  end

  def test_can_scan_tokens_with_lookahead
    scanner = Scanner.new '!!====<<=>>='
    actual = scanner.scan_tokens.map(&:type)
    expected = [
      :BANG,
      :BANG_EQUAL,
      :EQUAL_EQUAL,
      :EQUAL,
      :LESS,
      :LESS_EQUAL,
      :GREATER,
      :GREATER_EQUAL,
      :EOF
    ]
    assert_equal expected, actual
  end

  def test_can_scan_slash
    scanner = Scanner.new "/"
    expected = [:SLASH, :EOF]
    assert_equal expected, scanner.scan_tokens.map(&:type)
  end

  def test_can_scan_comments
    scanner = Scanner.new "// this is a comment"
    expected = [:EOF]
    assert_equal expected, scanner.scan_tokens.map(&:type)
  end

  def test_can_scan_whitespace
    scanner = Scanner.new " \t\l\n\n+"
    tokens = scanner.scan_tokens

    expected = [:PLUS, :EOF]
    assert_equal expected, tokens.map(&:type)
    assert_equal 3, scanner.scan_tokens.first.line
  end

  def test_can_scan_strings
    scanner = Scanner.new '"I am a string"'

    tokens = scanner.scan_tokens
    expected = [:STRING, :EOF]
    assert_equal expected, tokens.map(&:type)
    assert_equal 'I am a string', tokens.first.lexeme
  end

  def test_can_scan_ints
    scanner = Scanner.new '1234'

    tokens = scanner.scan_tokens
    expected = [:NUMBER, :EOF]
    assert_equal expected, tokens.map(&:type)
    assert_equal 1234.0, tokens.first.lexeme
  end

  def test_can_scan_floats
    scanner = Scanner.new '12.34'

    tokens = scanner.scan_tokens
    expected = [:NUMBER, :EOF]
    assert_equal expected, tokens.map(&:type)
    assert_equal 12.34, tokens.first.lexeme
  end

  def test_can_scan_reserved_keywords
    assert_token :AND, 'and'
    assert_token :CLASS, 'class'
    assert_token :ELSE, 'else'
    assert_token :FALSE, 'false'
    assert_token :FOR, 'for'
    assert_token :FUN, 'fun'
    assert_token :IF, 'if'
    assert_token :NIL, 'nil'
    assert_token :OR, 'or'
    assert_token :PRINT, 'print'
    assert_token :RETURN, 'return'
    assert_token :SUPER, 'super'
    assert_token :THIS, 'this'
    assert_token :TRUE, 'true'
    assert_token :VAR, 'var'
    assert_token :WHILE, 'while'
  end
end
