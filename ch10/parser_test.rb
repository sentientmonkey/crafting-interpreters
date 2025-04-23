#!/usr/bin/env ruby

require_relative 'test_helper'

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
    statements = parser.parse

    actual_ast = AstPrinter.new.print(statements)
    assert_equal expected_ast, actual_ast
  end

  def test_equality
    assert_ast "(== 1.0 2.0)", "1 == 2;"
    assert_ast "(!= 1.0 2.0)", "1 != 2;"
  end

  def test_comparison
    assert_ast "(> 1.0 2.0)", "1 > 2;"
    assert_ast "(>= 1.0 2.0)", "1 >= 2;"
    assert_ast "(< 1.0 2.0)", "1 < 2;"
    assert_ast "(<= 1.0 2.0)", "1 <= 2;"
  end

  def test_term
    assert_ast "(+ 1.0 2.0)", "1 + 2;"
    assert_ast "(- 1.0 2.0)", "1 - 2;"
  end

  def test_factor
    assert_ast "(* 1.0 2.0)", "1 * 2;"
    assert_ast "(/ 1.0 2.0)", "1 / 2;"
  end

  def test_primary
    assert_ast "nil", "nil;"
    assert_ast "true", "true;"
    assert_ast "false", "false;"
    assert_ast "1.0", "1;"
    assert_ast "1.75", "1.75;"
    assert_ast '"a string"', '"a string";'
  end

  def test_unary
    assert_ast "(! false)", "!false;"
    assert_ast "(- 42.0)", "-42;"
  end

  def test_group
    assert_ast "(+ (group (/ 4.0 2.0)) 5.0)", "(4 / 2) + 5;"
  end

  def test_print
    assert_ast '(print "hello")', 'print "hello";'
    assert_ast '(print true)', 'print true;'
    assert_ast '(print (+ 2.0 1.0))', 'print 2 + 1;'
  end

  def test_variable_declaration
    assert_ast '(var a 1.0)', 'var a = 1;'
    assert_ast '(var b (+ 2.0 1.0))', 'var b = 2 + 1;'
  end

  def test_variable_expression
    assert_ast '(+ a b)', 'a + b;'
  end

  def test_block_expression
    assert_ast '(block 2.0)', '{ 2; }'
    assert_ast '(block (var a 1.0) (a (+ a 1.0)))', '{ var a = 1; a = a + 1; }'
  end

  def test_if
    assert_ast '(if true 1.0 2.0)', 'if (true) 1.0; else 2;'
    assert_ast '(if true 1.0)', 'if (true) 1.0;'
    assert_ast '(if (> 2.0 1.0) (block 2.0) (block 1.0))', 'if (2 > 1) { 2.0; } else { 1.0 ;}'
    assert_ast '(if (> 2.0 1.0) (block 2.0))', 'if (2 > 1) { 2.0; }'
  end

  def test_logical
    assert_ast '(or true false)', 'true or false;'
    assert_ast '(and true false)', 'true and false;'
    assert_ast '(or 1.0 (and 2.0 6.0))', '1 or 2 and 6;'
    assert_ast '(or (and 1.0 2.0) 6.0)', '1 and 2 or 6;'
  end

  def test_while
    assert_ast '(while true (print "hello"))', 'while (true) print "hello";'
  end

  def test_for
    assert_ast '(block (var i 0.0) (while (< i 10.0) (block (print i) (i (+ i 1.0)))))', 'for (var i = 0; i < 10; i = i + 1) print i;'
  end

  def test_function_call
    assert_ast '(average 1.0 2.0)', 'average(1,2);'
    assert_ast '(clock)', 'clock();'
  end

  def test_function_definition
    assert_ast '(def (echo s) (print s))', 'fun echo(s) { print s; }'
    assert_ast '(def (add a b) (print (+ a b)))', 'fun add(a, b) { print a + b; }'
    assert_ast '(def (sayHi) (print "hello"))', 'fun sayHi() { print "hello"; }'
  end

  def test_function_with_return
    assert_ast '(def (add a b) (return (+ a b)))', 'fun add(a, b) { return a + b; }'
  end
end
