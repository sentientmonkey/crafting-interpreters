#!/usr/bin/env ruby

require_relative 'expr'
require_relative 'stmt'

class Visitor
  include Expr::Visitor
  include Stmt::Visitor
end
