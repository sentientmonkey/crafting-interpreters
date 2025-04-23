require_relative 'lox_runtime_error'

class Environment
  attr_reader :values, :enclosing

  def initialize(enclosing = nil)
    @values = {}
    @enclosing = enclosing
  end

  def define(name, value)
    @values[name] = value
  end

  def ancestor(distance)
    environment = self
    0.upto(distance-1) do |i|
      environment = environment.enclosing
    end

    environment
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

  def get_at(distance, name)
    ancestor(distance).values[name]
  end

  def assign_at(distance, name, value)
    ancestor(distance).values[name.lexeme] = value
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
