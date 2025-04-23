require_relative 'test_helper'

require_relative 'scanner'
require_relative 'parser'
require_relative 'resolver'
require_relative 'ast_printer'
require_relative 'lox'

class ResolverTest < Minitest::Test
  class MockInterpreter
    attr_reader :resolves
    def initialize
      @resolves = []
    end

    def resolve(expr, depth)
      self.resolves << [expr, depth]
    end
  end

  def resolve(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    parser = Parser.new(tokens)
    statements = parser.parse

    interpreter = MockInterpreter.new

    resolver = Resolver.new(interpreter)
    resolver.resolve(statements)

    interpreter.resolves
  end

  def assert_resolved(expected, source)
    ast_printer = AstPrinter.new
    actual_resolves = resolve(source)

    ast = actual_resolves.map do |expr, depth|
      [ast_printer.print([expr]), depth]
    end

    assert_equal(expected, ast)
  end

  def test_resolves_for_loop
    code = 'for (var i = 0; i < 10; i = i + 1) print i;'
    expected = [
      ["i", 0], 
      ["i", 1],
      ["i", 1],
      ["(i (+ i 1.0))", 1]
    ]

    assert_resolved(expected, code)
  end

  def test_resolves_for_class
    code = <<~CODE
    class Breakfast {
      cook() {
        print "Eggs a-frying'!";
      }

      serve(who) {
        print "Enjoy your breakfast, " + who + ".";
      }
    }
    CODE

    expected = [
      ["who", 0],
    ]

    assert_resolved(expected, code)
  end
end
