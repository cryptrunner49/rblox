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
        # Load history from file (optional)
        history_file = File.expand_path('~/.rblox_history')
        File.readlines(history_file, chomp: true).each { |line| Readline::HISTORY << line } if File.exist?(history_file)
        
        # Autocompletion 
        Readline.completion_proc = proc { |input|
          %w[print if else while for].grep(/^#{Regexp.escape(input)}/)
        }

        puts 'rblox 0.0.1'
        puts 'CTRL+C or CTRL+D (CTRL+Z on Windows) to quit'
        begin
          loop do
            line = Readline.readline('rblox>> '.red, true)
            break if line.nil? || line.empty? || %w[exit exit! quit].include?(line)
      
            run(line)
          end
        rescue Interrupt
        ensure
          # Save history to file (optional)
          File.write(history_file, Readline::HISTORY.to_a.join("\n") + "\n") if Readline::HISTORY.any?
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
