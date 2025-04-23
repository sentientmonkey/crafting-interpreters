#!/usr/bin/env ruby

def define_type(writer, base_name, class_name, fields)
  field_symbols = fields.map {|f| ":#{f}" }.join(', ')
  field_params = fields.join(', ')
  field_assignment = fields.map {|f| "      @#{f} = #{f}" }.join("\n")

  writer.puts <<~TYPE
  class #{class_name} < #{base_name}
    attr_reader #{field_symbols}

    def initialize(#{field_params})
#{field_assignment}
    end

    def accept(visitor)
      visitor.visit_#{class_name.downcase}_#{base_name.downcase}(self)
    end
  end

  TYPE
end

def underscore(s)
  s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
end

def define_ast(output_dir, base_name, types)
  File.open(File.join(output_dir, "#{base_name.downcase}.rb"), 'w') do |writer|
    writer.puts <<~BASE
    #!/usr/bin/env ruby

    class #{base_name}

    BASE

    define_visitor(writer, base_name, types)

    types.each do |type|
      class_name, fields  = type.split(':')
      field_values = fields
        .strip
        .split(', ')
        .map{ |f| f.split(' ').last }
        .map{ |f| underscore(f) }
      define_type(writer, base_name, class_name.strip, field_values)
    end

    writer.puts "end"
  end
end

def define_visitor(writer, base_name, types)
  writer.puts <<-MODULE
  # These are primarly for documentation since ruby doesn't have
  # interfaces.
  module Visitor
  MODULE

  types.each do |type|
    class_name  = type.split(':').first.strip
  
    writer.puts <<-VISITOR
    def visit_#{class_name.downcase}_#{base_name.downcase}(#{base_name.downcase})
      raise 'implement'
    end

    VISITOR
  end

  writer.puts <<-ENDMODULE
    def accept(visitor)
      raise 'implement'
    end
  end

  ENDMODULE
end

def main
  if ARGV.size != 1
    puts "Usage: generate_ast.rb <output directory>"
    exit 64
  end

  output_dir = ARGV[0]

  define_ast(
    output_dir,
    'Expr',
    ["Assign   : Token name, Expr value",
     "Binary   : Expr left, Token operator, Expr right",
     "Call     : Expr callee, Token paren, List<Expr> arguments",
     "Grouping : Expr expression",
     "Literal  : Object value",
     "Logical  : Expr left, Token operator, Expr right",
     "Unary    : Token operator, Expr right",
     "Variable : Token name",
    ],
  )

  define_ast(
    output_dir,
    'Stmt',
    ["Block      : List<Stmt> statements",
     "Expression : Expr expression",
     "If         : Expr condition, Stmt thenBranch, Stmt elseBranch",
     "Function   : Token name, List<Token> params, List<Stmt> body",
     "Print      : Expr expression",
     "Return     : Token keyword, Expr value",
     "Var        : Token name, Expr initializer",
     "While      : Expr condition, Stmt body",
    ],
  )
end

if __FILE__ == $0
  main
end
