#!/usr/bin/env ruby
# frozen_string_literal: true

require 'readline'

require_relative 'lexical/analyzer'
require_relative 'lexical/token_type'
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
        exit(70) if Runner.had_runtime_error
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
      
            begin
              run(line)
            rescue StandardError => e
              # Print the error message and continue the loop.
              puts "Error: #{e.message}"
            end
          end
        rescue Interrupt
          puts "\n"
        ensure
          # Save history to file (optional)
          File.write(history_file, Readline::HISTORY.to_a.join("\n") + "\n") if Readline::HISTORY.any?
          puts EXIT_MESSAGE
          exit(0)
        end
      end

      def run(source)
        #puts "Processing source: #{source}"
        analyzer = Lexical::Analyzer.new(source)
        tokens = analyzer.scan_tokens
        #puts "Tokens: #{tokens.map(&:to_s)}"

        parser = Syntax::Parser.new(tokens)
        statements = parser.parse

        if statements.nil?
          puts 'Parse error occurred'
          @had_error = true
          return
        end

        #puts 'Statements parsed:'
        #statements.each { |stmt| puts Generator::AstPrinter.new.print(stmt) }

        # Use a persistent interpreter instance.
        @interpreter ||= Interpreter::ExpressionEvaluator.new
        @interpreter.interpret(statements)
      end

      def error(token, message)
        if token.type == Lexical::TokenType::EOF
          report(token.line, ' at end', message)
        else
          report(token.line, " at '#{token.lexeme}'", message)
        end
      end

      private

      #def report(line, where, message)
     #   source_line = @source.split("\n")[line - 1]
     #   warn "[line #{line}] Error#{where}: #{message}"
      #  warn "  #{source_line}"
      #  warn "  " + (" " * (where.to_i - 1)) + "^"
      #end

      def report(line, where, message)
        STDERR.puts "[line #{line}] Error#{where}: #{message}".yellow
        @had_error = true
      end
      
      def runtime_error(error)
        warn "#{error.message}\n[line #{error.token.line}]"
        @had_runtime_error = true
      end
    end
  end
end

Lox::Runner.main(ARGV)
