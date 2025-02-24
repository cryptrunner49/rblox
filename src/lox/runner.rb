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

        lox_terms = %w[if else while for print true false nil + - * / == != < > <= >= ( ) { } ;]
        Readline.completion_proc = proc do |input|
          lox_terms.grep(/^#{Regexp.escape(input)}/)
        end
        Readline.completion_append_character = ' '

        begin
          loop do
            line = Readline.readline('rblox>> '.red, true)
            break if line.nil? || line.empty? || %w[exit exit! quit].include?(line.strip)

            run(line)
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
        statements = parser.parse

        if statements.nil?
          @had_error = true
          return
        end

        evaluator = Interpreter::ExpressionEvaluator.new
        statements.each do |stmt|
          stmt.accept(evaluator)
        end
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
