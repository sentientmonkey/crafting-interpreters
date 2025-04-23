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

  def test_if_statement
    assert_interp(/yes/, 'if (true) print "yes"; else print "no";')
    assert_interp(/no/, 'if (false) print "yes"; else print "no";')
    assert_interp(/yes/, 'if (true) print "yes";')
  end

  def test_logical
    assert_interp(/false/, 'print true and false;')
    assert_interp(/false/, 'print false and true;')
    assert_interp(/true/, 'print true and true;')
    assert_interp(/false/, 'print false and false;')

    assert_interp(/true/, 'print true or false;')
    assert_interp(/true/, 'print false or true;')
    assert_interp(/true/, 'print true or true;')
    assert_interp(/false/, 'print false or false;')

    # or has higher precidence than and
    assert_interp(/true/, 'print true or false and true;')
    assert_interp(/true/, 'print true and false or true;')

    assert_interp(/hi/, 'print "hi" or 2;')
    assert_interp(/yes/, 'print nil or "yes";')
  end

  def test_while
    assert_interp(/5/, 'var i=0; while (i < 5) i = i + 1; print i;')
  end

  def test_for
    code = 'for (var i = 0; i < 10; i = i + 1) print i;'
    expected = <<~OUT
    0
    1
    2
    3
    4
    5
    6
    7
    8
    9
    OUT

    assert_interp(expected, code)
  end

  def test_for_fib
    code = <<~CODE
    var a = 0;
    var temp;

    for (var b = 1; a < 10000; b = temp + b) {
      print a;
      temp = a;
      a = b;
    }
    CODE

    expected = <<~OUT
    0
    1
    1
    2
    3
    5
    8
    13
    21
    34
    55
    89
    144
    233
    377
    610
    987
    1597
    2584
    4181
    6765
    OUT

    assert_interp(expected, code)
  end

  def test_native_function
    mock = Minitest::Mock.new
    mock.expect(:to_i, 1660338499)

    Time.stub(:now, mock) do
      expected = <<~OUT
        1660338499
      OUT
      assert_interp(expected, "print clock();")
    end

    mock.verify
  end

  def test_user_defined_functions
    code = <<~CODE
    fun add(a, b) {
      print a + b;
    }
    print add;
    add(1,2);
    CODE

    expected = <<~OUT
    <fn add>
    3
    OUT
    assert_interp(expected, code)

    code = <<~CODE
    fun sayHi(first, last) {
      print "Hi, " + first + " " + last + "!";
    }

    sayHi("Dear", "Reader");
    CODE

    expected = <<~OUT
    Hi, Dear Reader!
    OUT
    assert_interp(expected, code)
  end

  def test_user_defined_arity
    code = <<~CODE
    fun add(a, b, c) {
      print a + b + c;
    }
    add(1, 2, 3, 4);
    CODE
    assert_interp_error(/Expected 3 arguments but got 4/, code)

    code = <<~CODE
    fun add(a, b, c) {
      print a + b + c;
    }
    add(1, 2);
    CODE
    assert_interp_error(/Expected 3 arguments but got 2/, code)
  end

  def test_return
    code = <<~CODE
    fun count(n) {
      while (n < 100) {
        if (n == 3) return n; // <--
        print n;
        n = n + 1;
      }
    }

    count(1);
    CODE

    expected = <<~OUT
    1
    2
    OUT
    assert_interp(expected, code)
  end

  def test_closures
    code = <<~CODE
    fun makeCounter() {
      var i = 0;
      fun count() {
        i = i + 1;
        print i;
      }

      return count;
    }

    var counter = makeCounter();
    counter(); // "1".
    counter(); // "2".
    CODE

    expected = <<~OUT
    1
    2
    OUT

    assert_interp(expected, code)
  end
end
