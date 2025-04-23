#!/usr/bin/env ruby

require_relative 'scanner'

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
    scanner.scan_tokens.each do |token|
      puts token
    end
    @@had_error ? 65 : 0
  end

  def self.error line, message
    report line, '', message
  end

  def self.report line, where, message
    warn "[line #{line}] Error#{where}: #{message}"
    @@had_error = true
  end
end

if __FILE__ == $0
  exit Lox.main ARGV
end
