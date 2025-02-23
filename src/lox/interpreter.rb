#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lexical/analyzer'
require_relative 'utils/string_colors'

module Lox
  class Interpreter
    class << self
      attr_accessor :had_error

      @had_error = false

      def main(args)
        if args.length > 1
          puts 'Usage: rblox [script]'
          exit(64)
        elsif args.length == 1
          run_file(args[0])
        else
          run_prompt
        end
      end

      def run_file(file_path)
        content = File.read(file_path, encoding: 'UTF-8')
        run(content)
        exit(65) if Interpreter.had_error
      end

      def run_prompt
        puts 'rblox 0.0.1'
        puts 'CTRL+C to quit'
        loop do
          print 'rblox>> '.red
          line = gets&.chomp
          break if line.nil? || line.empty?

          run(line)
          false
        end
      end

      def run(_source)
        # Placeholder for execution logic
      end

      def error(line, message)
        report(line, '', message)
      end

      private

      def report(line, where, message)
        warn "[line #{line}] Error#{where}: #{message}"
        @had_error = true
      end
    end
  end
end

# Example usage at the bottom of the file or in a separate main.rb:
# Lox::Interpreter.main(ARGV)

# Example usage:
# Lox::Interpreter.error(10, 'Unexpected character')
# puts Lox::Interpreter.had_error # => true

analyzer = Lox::Lexical::Analyzer.new(ARGV[0])
puts analyzer.scan_tokens
