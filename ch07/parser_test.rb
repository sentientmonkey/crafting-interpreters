#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'

require_relative 'token'
require_relative 'scanner'
require_relative 'parser'
require_relative 'ast_printer'
require_relative 'lox'

class ParserTest < Minitest::Test
  def assert_ast(expected_ast, source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    parser = Parser.new(tokens)
    expression = parser.parse

    actual_ast = AstPrinter.new.print(expression)
    assert_equal expected_ast, actual_ast
  end

  def test_equality
    assert_ast "(== 1.0 2.0)", "1 == 2"
    assert_ast "(!= 1.0 2.0)", "1 != 2"
  end

  def test_comparison
    assert_ast "(> 1.0 2.0)", "1 > 2"
    assert_ast "(>= 1.0 2.0)", "1 >= 2"
    assert_ast "(< 1.0 2.0)", "1 < 2"
    assert_ast "(<= 1.0 2.0)", "1 <= 2"
  end

  def test_term
    assert_ast "(+ 1.0 2.0)", "1 + 2"
    assert_ast "(- 1.0 2.0)", "1 - 2"
  end

  def test_factor
    assert_ast "(* 1.0 2.0)", "1 * 2"
    assert_ast "(/ 1.0 2.0)", "1 / 2"
  end

  def test_primary
    assert_ast "nil", "nil"
    assert_ast "true", "true"
    assert_ast "false", "false"
    assert_ast "1.0", "1"
    assert_ast "1.75", "1.75"
    assert_ast "a string", '"a string"'
  end

  def test_unary
    assert_ast "(! false)", "!false"
    assert_ast "(- 42.0)", "-42"
  end

  def test_group
    assert_ast "(+ (group (/ 4.0 2.0)) 5.0)", "(4 / 2) + 5"
  end
end
