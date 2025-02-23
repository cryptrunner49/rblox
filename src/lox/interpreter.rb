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
        begin
          loop do
            print 'rblox>> '.red
            line = gets&.chomp
            break if line.nil? || line.empty? || line = "exit" || line == "exit!" || line == "quit"

            run(line)
            false
          end
        rescue Interrupt
          puts "\n"
        ensure
          puts "\nExiting rblox. Goodbye!"
          exit(0)
        end
      end

      def run(source)
        analyzer = Lox::Lexical::Analyzer.new(source)
        tokens = analyzer.scan_tokens
        tokens.each { |token| puts token }
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

Lox::Interpreter.main(ARGV)