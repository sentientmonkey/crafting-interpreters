#!/usr/bin/env ruby

require_relative 'scanner'
require_relative 'parser'
require_relative 'ast_printer'

class Lox
  def self.main args
    # have to reset because class state :/
    @@had_error = false
    if args.size > 1
      puts 'Usage: rlox [script]'
      64
    elsif args.size == 1
      run_file args[0]
    else
      run_prompt
    end
  end

  private

  def self.run_file path
    run File.read(path)
  end

  def self.run_prompt
    while true
      print '> '
      line = STDIN.gets
      break unless line
      run line
    end
  end

  def self.run source
    scanner = Scanner.new source
    tokens = scanner.scan_tokens
    parser = Parser.new(tokens)
    expression = parser.parse
    return if @@had_error

    puts AstPrinter.new.print(expression)

    @@had_error ? 65 : 0
  end

  def self.error token, message
    if token.type == :EOF
      report token.line, " at end", message
    else
      report token.line, " at '#{token.lexeme}'", message
    end
  end

  def self.report line, where, message
    warn "[line #{line}] Error#{where}: #{message}"
    @@had_error = true
  end
end

if __FILE__ == $0
  exit Lox.main ARGV
end
