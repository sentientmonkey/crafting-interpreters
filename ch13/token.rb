#!/usr/bin/env ruby

Token = Struct.new('Token', :type, :lexeme, :literal, :line) do
  def to_s
    "#{type} #{lexeme} #{literal}"
  end
end
