require_relative 'lox_callable'
require_relative 'environment'
require_relative 'return'

class LoxFunction
  include LoxCallable

  def initialize(declaration, closure, is_initializer)
    @closure = closure
    @declaration = declaration
    @is_initializer = is_initializer
  end

  def bind(instance)
    environment = Environment.new(@closure)
    environment.define('this', instance)
    LoxFunction.new(@declaration, environment, @is_initializer)
  end

  def arity
    @declaration.params.size
  end

  def call(interpreter, arguments)
    environment = Environment.new(@closure)
    0.upto(@declaration.params.size-1) do |i|
      environment.define(
        @declaration.params[i].lexeme,
        arguments[i],
      )
    end

    begin
      interpreter.execute_block(@declaration.body, environment)
    rescue Return => return_value
      # :/ Not sure why this is needed, it passed tests without addition
      return @closure.get_at(0, 'this') if @is_initializer

      return return_value.value
    end

    return @closure.get_at(0, 'this') if @is_initializer

    nil
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
