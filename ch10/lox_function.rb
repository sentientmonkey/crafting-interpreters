require_relative 'lox_callable'
require_relative 'return'

class LoxFunction
  include LoxCallable

  def initialize(declaration, closure)
    @closure = closure
    @declaration = declaration
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
      return return_value.value
    end

    nil
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
