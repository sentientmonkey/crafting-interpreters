require_relative 'lox_runtime_error'

class LoxInstance
  def initialize(klass)
    @klass = klass
    @fields = {}
  end

  def get(name)
    if @fields.key?(name.lexeme)
      return @fields[name.lexeme]
    end

    method = @klass.find_method(name.lexeme)
    return method.bind(self) if method

    raise LoxRuntimeError.new(
      name,
      "Undefined property '#{name.lexeme}'",
    )
  end

  def set(name, value)
    @fields[name.lexeme] = value
  end

  def to_s
    "#{@klass.name} instance"
  end
end
