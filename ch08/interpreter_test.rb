#!/usr/bin/env ruby

require_relative 'test_helper'

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
    statements = parser.parse

    Interpreter.new.interpret(statements)
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
    assert_interp(/true/, 'print 1 == 1;')
    assert_interp(/false/, 'print 1 == 2;')
    assert_interp(/true/, 'print "1" == "1";')
    assert_interp(/false/, 'print "1" == "2";')
    assert_interp(/false/, 'print 1 == "1";')

    assert_interp(/false/, 'print 1 != 1;')
    assert_interp(/true/, 'print 1 != 2;')
    assert_interp(/false/, 'print "1" != "1";')
    assert_interp(/true/, 'print "1" != "2";')
    assert_interp(/true/, 'print 1 != "1";')
  end

  def test_comparison
    assert_interp(/true/, 'print 2 > 1;')
    assert_interp(/false/, 'print 1 > 1;')
    assert_interp(/true/, 'print 1 >= 1;')
    assert_interp(/false/, 'print 0 >= 1;')
    assert_interp(/true/, 'print 1 < 2;')
    assert_interp(/false/, 'print 1 < 1;')
    assert_interp(/true/, 'print 1 <= 1;')
    assert_interp(/true/, 'print 0 <= 1;')
  end

  def test_term
    assert_interp(/3/, "print 1 + 2;")
    assert_interp(/-1/, "print 1 - 2;")
    assert_interp(/2.5/, "print 1.5 + 1;")
    assert_interp(/0.5/, "print 1.5 - 1;")
  end

  def test_factor
    assert_interp(/6/, "print 2 * 3;")
    assert_interp(/1.5/, "print 0.5 * 3;")
    assert_interp(/3/, "print 6 / 2;")
    assert_interp(/2.5/, "print 5 / 2;")
  end

  def test_primary
    assert_interp(/nil/, "print nil;")
    assert_interp(/true/, "print true;")
    assert_interp(/false/, "print false;")
    assert_interp(/1/, "print 1;")
    assert_interp(/1.75/, "print 1.75;")
    assert_interp(/a string/, 'print "a string";')
  end

  def test_unary
    assert_interp(/true/, "print !false;")
    assert_interp(/false/, "print !true;")
    assert_interp(/false/, "print !0;")
    assert_interp(/false/, "print !1;")
    assert_interp(/true/, "print !nil;")
    assert_interp(/false/, 'print !"string";')
  end

  def test_group
    assert_interp(/7/, "print (4 / 2) + 5;")
  end

  def test_errors
    assert_interp_error(/Operands must be numbers/, '5 > "string";')
    assert_interp_error(/Operands must be two numbers or two strings/, '1 + "1";')
  end

  def test_initialization
    assert_interp(/3/, "var a = 1; var b = 2; print a + b;")
  end

  def test_assignment
    assert_interp(/3/, "var a = 1; a = a + 2; print a;")
  end

  def test_block_assignment
    assert_interp(/1/, "var a = 1; { var a = a + 2; } print a;")
    assert_interp(/3/, "var a = 1; { a = a + 2; } print a;")
    assert_interp(/3/, "var a = 1; { var a = a + 2; print a; }")
  end

  def test_block_scope
    code = <<~LOX
    var a = "global a";
    var b = "global b";
    var c = "global c";
    {
      var a = "outer a";
      var b = "outer b";
      {
        var a = "inner a";
        print a;
        print b;
        print c;
      }
      print a;
      print b;
      print c;
    }
    print a;
    print b;
    print c;
    LOX

    expected = <<~OUT
    inner a
    outer b
    global c
    outer a
    outer b
    global c
    global a
    global b
    global c
    OUT

    assert_interp(expected, code)
  end
end
