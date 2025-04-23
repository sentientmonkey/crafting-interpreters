#!/usr/bin/env ruby

class LoxRuntimeError < StandardError
  attr_reader :token

  def initialize(token, message)
    @token = token
    super(message)
  end
end
