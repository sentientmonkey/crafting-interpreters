#!/usr/bin/env ruby

class Expr

  # These are primarly for documentation since ruby doesn't have
  # interfaces.
  module Visitor
    def visit_assign_expr(expr)
      raise 'implement'
    end

    def visit_binary_expr(expr)
      raise 'implement'
    end

    def visit_call_expr(expr)
      raise 'implement'
    end

    def visit_grouping_expr(expr)
      raise 'implement'
    end

    def visit_literal_expr(expr)
      raise 'implement'
    end

    def visit_logical_expr(expr)
      raise 'implement'
    end

    def visit_unary_expr(expr)
      raise 'implement'
    end

    def visit_variable_expr(expr)
      raise 'implement'
    end

    def accept(visitor)
      raise 'implement'
    end
  end

  class Assign < Expr
    attr_reader :name, :value

    def initialize(name, value)
      @name = name
      @value = value
    end

    def accept(visitor)
      visitor.visit_assign_expr(self)
    end
  end

  class Binary < Expr
    attr_reader :left, :operator, :right

    def initialize(left, operator, right)
      @left = left
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visit_binary_expr(self)
    end
  end

  class Call < Expr
    attr_reader :callee, :paren, :arguments

    def initialize(callee, paren, arguments)
      @callee = callee
      @paren = paren
      @arguments = arguments
    end

    def accept(visitor)
      visitor.visit_call_expr(self)
    end
  end

  class Grouping < Expr
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visit_grouping_expr(self)
    end
  end

  class Literal < Expr
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def accept(visitor)
      visitor.visit_literal_expr(self)
    end
  end

  class Logical < Expr
    attr_reader :left, :operator, :right

    def initialize(left, operator, right)
      @left = left
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visit_logical_expr(self)
    end
  end

  class Unary < Expr
    attr_reader :operator, :right

    def initialize(operator, right)
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visit_unary_expr(self)
    end
  end

  class Variable < Expr
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def accept(visitor)
      visitor.visit_variable_expr(self)
    end
  end

end
