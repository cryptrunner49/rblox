#!/usr/bin/env ruby
# frozen_string_literal: true

require 'readline'

require_relative 'lexical/analyzer'
require_relative 'syntax/parser'
require_relative 'syntax/expr'
require_relative 'utils/string_colors'
require_relative '../../generator/ast_printer'

module Lox
  class Interpreter
    class << self
      attr_accessor :had_error

      @had_error = false

      EXIT_MESSAGE = "\nExiting rblox. Goodbye!"

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
        puts 'CTRL+C or CTRL+D (CTRL+Z on Windows) to quit'
        begin
          loop do
            print 'rblox>> '.red
            line = gets&.chomp
            break if line.nil? || line.empty? || line == 'exit' || line == 'exit!' || line == 'quit'

            run(line)
            false
          end
        rescue Interrupt
          puts "\n"
        ensure
          puts EXIT_MESSAGE
          exit(0)
        end
      end

      def run(source)
        analyzer = Lexical::Analyzer.new(source)
        tokens = analyzer.scan_tokens
        parser = Syntax::Parser.new(tokens)
        expression = parser.parse

        if expression.nil?
          @had_error = true
          return
        end

        puts Generator::AstPrinter.new.print(expression)
        expression
      end

      def error(token, message)
        if token.type == TokenType::EOF
          report(token.line, ' at end', message)
        else
          report(token.line, " at '#{token.lexeme}'", message)
        end
      end

      private

      def report(line, where, message)
        warn "[line #{line}] Error#{where}: #{message}"
      end
    end
  end
end

Lox::Interpreter.main(ARGV)
