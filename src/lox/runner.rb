#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  require 'readline'
rescue LoadError
  require 'rb-readline'
end

require_relative 'lexical/analyzer'
require_relative 'syntax/parser'
require_relative 'syntax/expr'
require_relative 'interpreter/expression_evaluator'
require_relative 'utils/string_colors'
require_relative '../../generator/ast_printer'

module Lox
  class Runner
    class << self
      attr_accessor :had_error, :had_runtime_error

      @had_error = false
      @had_runtime_error = false

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
        exit(65) if Runner.had_error
      end

      def run_prompt
        puts 'rblox 0.0.1'
        puts 'CTRL+C or CTRL+D (CTRL+Z on Windows) to quit'
        # Load history from file (optional)

        history_file = File.expand_path('~/.rblox_history')

        File.readlines(history_file, chomp: true).each { |line| Readline::HISTORY << line } if File.exist?(history_file)

        # Autocompletion
        lox_terms = %w[if else while for print true false nil + - * / == != < > <= >= ( ) { } ;]
        Readline.completion_proc = proc { |input|
          lox_terms.grep(/^#{Regexp.escape(input)}/)
        }

        begin
          loop do
            line = Readline.readline('rblox>> '.red, true)
            break if line.nil? || line.empty? || %w[exit exit! quit].include?(line)

            run(line)
          end
        rescue Interrupt
          puts "\n"
        ensure
          # Save history to file (optional)
          File.write(history_file, "#{Readline::HISTORY.to_a.join("\n")}\n") if Readline::HISTORY.any?
          puts EXIT_MESSAGE
          exit(0)
        end
      end

      def run(source)
        puts "Processing source: #{source}"
        analyzer = Lexical::Analyzer.new(source)
        tokens = analyzer.scan_tokens
        puts "Tokens: #{tokens.map(&:to_s)}"

        parser = Syntax::Parser.new(tokens)
        statements = parser.parse

        if statements.nil?
          puts 'Parse error occurred'
          @had_error = true
          return
        end

        puts 'Statements parsed:'
        statements.each { |stmt| puts Generator::AstPrinter.new.print(stmt) }

        evaluator = Interpreter::ExpressionEvaluator.new
        evaluator.interpret(statements)
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

      def runtime_error(error)
        warn "#{error.message}\n[line #{error.token.line}]"
        @had_runtime_error = true
      end
    end
  end
end

Lox::Runner.main(ARGV)
