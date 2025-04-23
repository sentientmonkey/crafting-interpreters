#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'

require_relative 'token'
require_relative 'scanner'
require_relative 'parser'
require_relative 'interpreter'
require_relative 'lox'

class InterpreterTest < Minitest::Test
  def interpret(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    parser = Parser.new(tokens)
    expression = parser.parse
    
    Interpreter.new.interpret(expression)
  end

  def assert_interp(expected, source)
    assert_output(expected) do
      interpret(source)
    end
  end

  def assert_interp_error(expected, source)
    assert_output(nil, expected) do
      interpret(source)
    end
  end

  def test_equality
    assert_interp(/true/, '1 == 1')
    assert_interp(/false/, '1 == 2')
    assert_interp(/true/, '"1" == "1"')
    assert_interp(/false/, '"1" == "2"')
    assert_interp(/false/, '1 == "1"')

    assert_interp(/false/, '1 != 1')
    assert_interp(/true/, '1 != 2')
    assert_interp(/false/, '"1" != "1"')
    assert_interp(/true/, '"1" != "2"')
    assert_interp(/true/, '1 != "1"')
  end

  def test_comparison
    assert_interp(/true/, '2 > 1')
    assert_interp(/false/, '1 > 1')
    assert_interp(/true/, '1 >= 1')
    assert_interp(/false/, '0 >= 1')
    assert_interp(/true/, '1 < 2')
    assert_interp(/false/, '1 < 1')
    assert_interp(/true/, '1 <= 1')
    assert_interp(/true/, '0 <= 1')
  end

  def test_term
    assert_interp(/3/, "1 + 2")
    assert_interp(/-1/, "1 - 2")
    assert_interp(/2.5/, "1.5 + 1")
    assert_interp(/0.5/, "1.5 - 1")
  end

  def test_factor
    assert_interp(/6/, "2 * 3")
    assert_interp(/1.5/, "0.5 * 3")
    assert_interp(/3/, "6 / 2")
    assert_interp(/2.5/, "5 / 2")
  end

  def test_primary
    assert_interp(/nil/, "nil")
    assert_interp(/true/, "true")
    assert_interp(/false/, "false")
    assert_interp(/1/, "1")
    assert_interp(/1.75/, "1.75")
    assert_interp(/a string/, '"a string"')
  end

  def test_unary
    assert_interp(/true/, "!false")
    assert_interp(/false/, "!true")
    assert_interp(/false/, "!0")
    assert_interp(/false/, "!1")
    assert_interp(/true/, "!nil")
    assert_interp(/false/, '!"string"')
  end

  def test_group
    assert_interp(/7/, "(4 / 2) + 5")
  end

  def test_errors
    assert_interp_error(/Operands must be numbers/, '5 > "string"')
    assert_interp_error(/Operands must be two numbers or two strings/, '1 + "1"')
  end
end
