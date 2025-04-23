require_relative 'lox_runtime_error'

class Environment
  def initialize(enclosing = nil)
    @values = {}
    @enclosing = enclosing
  end

  def define(name, value)
    @values[name.lexeme] = value
  end

  def get(name)
    if @values.include?(name.lexeme)
      @values[name.lexeme]
    elsif @enclosing
      @enclosing.get(name)
    else
      raise LoxRuntimeError.new(
        name,
        "Undefined variable '#{name.lexeme}'.",
      )
    end
  end

  def assign(name, value)
    if @values.include?(name.lexeme)
      @values[name.lexeme] = value
    elsif @enclosing
      @enclosing.assign(name, value)
    else
      raise LoxRuntimeError.new(
        name,
        "Undefined variable '#{name.lexeme}'.",
      )
    end
  end
end
