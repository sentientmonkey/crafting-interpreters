#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/pride'

require_relative 'lox'

class LoxTest < Minitest::Test
  def test_too_many_args_gives_usage
    out, _ = capture_io do
      result = Lox.main ['too', 'many']
      assert_equal result, 64
    end
    assert_match 'Usage: rlox [script]', out
  end

  def test_run_file_gives_contents
    out, _ = capture_io do
      result = Lox.main ['test.lox']
      assert_equal result, 0
    end
    expected = <<~EOS
      IDENTIFIER print  
      STRING Hello Hello
      SEMICOLON ;
       
      EOF  
    EOS
    assert_equal expected, out
  end

  def test_report_error
    _, err = capture_io do
      Lox.error 15, 'Unexpected "," in argument list.'
    end
    assert_match '[line 15] Error: Unexpected "," in argument list.', err
  end
end
