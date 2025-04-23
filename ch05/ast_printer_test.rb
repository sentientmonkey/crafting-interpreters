#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'

require_relative 'expr'
require_relative 'token'
require_relative 'ast_printer'


class AstPrinterTest < Minitest::Test
  def test_printer
    expression = Expr::Binary.new(
      Expr::Unary.new(
        Token.new(:MINUS, '-', nil, 1),
        Expr::Literal.new(123)),
        Token.new(:STAR, '*', nil, 1),
        Expr::Grouping.new(
          Expr::Literal.new(45.67)))

    actual = AstPrinter.new.print(expression)

    expected = '(* (- 123) (group 45.67))'

    assert_equal expected, actual
  end
end
