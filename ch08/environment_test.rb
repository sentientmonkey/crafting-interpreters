#!/usr/bin/env ruby

require_relative 'test_helper'

require_relative 'environment'
require_relative 'token'
require_relative 'lox_runtime_error'

class EnvironmentTest < Minitest::Test
  def setup
    @environment = Environment.new
    @token = Token.new(:VAR, 'a')
  end
  def test_can_define_value
    @environment.define(@token, 42)

    assert_equal 42, @environment.get(@token)
  end

  def test_can_assign_value
    @environment.define(@token, 0)
    @environment.assign(@token, 42)

    assert_equal 42, @environment.get(@token)
  end

  def test_errors_on_getting_undefined_variable
    ex = assert_raises LoxRuntimeError do
      @environment.get(@token)
    end

    assert_equal "Undefined variable 'a'.", ex.message
  end

  def test_errors_on_assigning_undefined_variable
    ex = assert_raises LoxRuntimeError do
      @environment.assign(@token, 45)
    end

    assert_equal "Undefined variable 'a'.", ex.message
  end

  def test_enclosed_environment
    enclosed_environment = Environment.new(@environment)
    other_token = Token.new(:VAR, 'b')
    @environment.define(@token, 21)
    enclosed_environment.define(other_token, 50)
    enclosed_environment.define(@token, 42)

    assert_equal 21, @environment.get(@token)
    assert_equal 42, enclosed_environment.get(@token)
    assert_equal 50, enclosed_environment.get(other_token)

    assert_raises LoxRuntimeError do
      @environment.get(other_token)
    end
  end
end
