#!/usr/bin/env ruby

require_relative 'scanner'
require_relative 'parser'
require_relative 'resolver'
require_relative 'interpreter'

class Lox
  def self.had_error
    @@had_error ||= false
  end

  def self.had_error=(had_error)
    @@had_error = had_error
  end

  def self.main args
    @@interpreter = Interpreter.new
    # have to reset because class state :/
    @@had_error = false
    @@had_runtime_error = false
    if args.size > 1
      puts 'Usage: rlox [script]'
      exit(64)
    elsif args.size == 1
      run_file args[0]
    else
      run_prompt
    end
  end

  private

  def self.run_file path
    run File.read(path)

    exit(65) if @@had_error
    exit(70) if @@had_runtime_error
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
    statements = parser.parse

    return if @@had_error

    resolver = Resolver.new(@@interpreter)
    resolver.resolve(statements)

    return if @@had_error

    @@interpreter.interpret(statements)
  end

  def self.error token, message
    if token.type == :EOF
      report token.line, " at end", message
    else
      report token.line, " at '#{token.lexeme}'", message
    end
  end

  def self.runtime_error error
    warn "#{error.message}\n[line #{error.token.line}]"
    @@had_runtime_error = true
  end

  def self.report line, where, message
    warn "[line #{line}] Error#{where}: #{message}"
    @@had_error = true
  end
end

if __FILE__ == $0
  Lox.main ARGV
end
