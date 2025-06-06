require_relative 'lox_callable'
require_relative 'lox_instance'

class LoxClass
  include LoxCallable

  attr_reader :name

  def initialize(name, superclass, methods)
    @name = name
    @superclass = superclass
    @methods = methods
  end

  def find_method(name)
    @methods.fetch(name) do
      @superclass&.find_method(name)
    end
  end

  def to_s
    name
  end

  def call(interpreter, arguments)
    instance = LoxInstance.new(self)
    initializer = find_method('init')
    if initializer
      initializer.bind(instance).call(interpreter, arguments)
    end

    instance
  end

  def arity
    initializer = find_method('init')
    if initializer
      initializer.arity
    else
      0
    end
  end
end
