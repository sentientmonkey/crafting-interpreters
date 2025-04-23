#!/usr/bin/env ruby

class Stmt

  # These are primarly for documentation since ruby doesn't have
  # interfaces.
  module Visitor
    def visit_block_stmt(stmt)
      raise 'implement'
    end

    def visit_expression_stmt(stmt)
      raise 'implement'
    end

    def visit_if_stmt(stmt)
      raise 'implement'
    end

    def visit_print_stmt(stmt)
      raise 'implement'
    end

    def visit_var_stmt(stmt)
      raise 'implement'
    end

    def visit_while_stmt(stmt)
      raise 'implement'
    end

    def accept(visitor)
      raise 'implement'
    end
  end

  class Block < Stmt
    attr_reader :statements

    def initialize(statements)
      @statements = statements
    end

    def accept(visitor)
      visitor.visit_block_stmt(self)
    end
  end

  class Expression < Stmt
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visit_expression_stmt(self)
    end
  end

  class If < Stmt
    attr_reader :condition, :then_branch, :else_branch

    def initialize(condition, then_branch, else_branch)
      @condition = condition
      @then_branch = then_branch
      @else_branch = else_branch
    end

    def accept(visitor)
      visitor.visit_if_stmt(self)
    end
  end

  class Print < Stmt
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visit_print_stmt(self)
    end
  end

  class Var < Stmt
    attr_reader :name, :initializer

    def initialize(name, initializer)
      @name = name
      @initializer = initializer
    end

    def accept(visitor)
      visitor.visit_var_stmt(self)
    end
  end

  class While < Stmt
    attr_reader :condition, :body

    def initialize(condition, body)
      @condition = condition
      @body = body
    end

    def accept(visitor)
      visitor.visit_while_stmt(self)
    end
  end

end
