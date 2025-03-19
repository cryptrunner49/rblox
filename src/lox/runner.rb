#!/usr/bin/env ruby
# frozen_string_literal: false

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
    # ======================================================================
    # Section: Runner Class Methods
    # Purpose: Contains methods to run Lox scripts from files or REPL.
    # ======================================================================

    class << self
      attr_accessor :had_error, :had_runtime_error

      @had_error = false
      @had_runtime_error = false

      EXIT_MESSAGE = "\nExiting rblox. Goodbye!".freeze unless defined?(EXIT_MESSAGE)

      def main(args)
        case args.length
        when 1
          run_file(args[0])
        when 0
          run_prompt
        else
          puts 'Usage: rblox [script]'
          exit(64)
        end
      end

      def run_file(file_path)
        content = File.read(file_path, encoding: 'UTF-8')
        run(content)
        exit(65) if Runner.had_error
        exit(70) if Runner.had_runtime_error
      end

      def run_prompt
        puts 'rblox 0.0.1'.cyan
        puts 'CTRL+C or CTRL+D (CTRL+Z on Windows) to quit'
        history_file = File.expand_path('~/.rblox_history')
        load_history(history_file)
        'rblox>> '.red
        bracket_stack = []
        in_multiline = false

        # Initialize autocomplete terms
        @completion_terms = %w[
          if else while for print return
          true false nil var fun class
          super this and or not
        ] + Lox::Lexical::TokenType.all_types.map { |t| t.to_s.downcase }

        Readline.completion_proc = proc do |input|
          current_line = Readline.line_buffer
          context_based_completions(current_line, input)
        end

        buffer = ''
        prompt = 'rblox>> '.red

        begin
          loop do
            line = Readline.readline(prompt, true)
            break if line.nil? || line.match(/^\s*(exit|quit)!?$/)

            # Handle empty line submission
            if line.strip.empty?
              next unless in_multiline

              buffer << "\n"
              next
            end

            # Update bracket stack
            line.each_char do |c|
              case c
              when '{', '(', '[' then bracket_stack.push(c)
              when '}'
                bracket_stack.pop if bracket_stack.last == '{'
              when ')'
                bracket_stack.pop if bracket_stack.last == '('
              when ']'
                bracket_stack.pop if bracket_stack.last == '['
              end
            end

            buffer << line << "\n"

            if bracket_stack.empty? && complete_statement?(buffer)
              process_buffer(buffer, history_file)
              buffer = ''
              prompt = 'rblox>> '.red
              in_multiline = false
            else
              prompt = ('  ' * bracket_stack.size) + '... '.yellow
              in_multiline = true
            end
          end
        rescue Interrupt
          puts "\n"
        ensure
          save_history(history_file)
          puts EXIT_MESSAGE
        end
      end

      def context_based_completions(line, input)
        # Basic context awareness
        case line.split.last
        when 'var' then variables_in_scope
        when 'print' then variables_in_scope
        else
          @completion_terms.grep(/^#{Regexp.escape(input)}/i)
        end
      end

      def variables_in_scope
        @interpreter&.environment&.instance_variable_get(:@values)&.keys || []
      end

      def process_buffer(buffer, _history_file)
        return unless buffer.strip == '?help'

        show_help
        nil
      end

      def show_help
        puts <<~HELP
          rblox REPL Commands:
            ?help      - Show this help
            ?clear     - Clear screen
            ?history   - Show command history
            ?vars      - Show current variables
            Ctrl+L     - Clear screen
            Ctrl+R     - Search history
            Tab        - Auto-completion
          #{'  '}
          Language Features:
            - Full Lox language support
            - Multiline input with automatic continuation
            - Syntax highlighting
            - Context-aware autocomplete
        HELP
      end

      def run(source)
        analyzer = Lexical::Analyzer.new(source)
        tokens = analyzer.scan_tokens

        parser = Syntax::Parser.new(tokens)
        statements = parser.parse

        if statements.nil?
          puts '[Parse Error] Invalid syntax detected'
          @had_error = true
          return
        end

        # Use a persistent interpreter instance.
        @interpreter ||= Interpreter::ExpressionEvaluator.new
        begin
          @interpreter.interpret(statements)
        rescue Lox::Interpreter::RuntimeError => e
          runtime_error(e)
        end
      end

      def error(token, message)
        if token.type == Lexical::TokenType::EOF
          report(token.line, ' at end', message)
        else
          report(token.line, " at '#{token.lexeme}'", message)
        end
      end

      def report(line, where, message)
        warn "[line #{line}] Error#{where}: #{message}".yellow
        @had_error = true
      end

      def runtime_error(error)
        warn "#{error.message}\n[line #{error.token.line}]"
        @had_runtime_error = true
      end

      private

      def balanced_brackets?(code)
        stack = []
        code.each_char do |c|
          case c
          when '{', '(', '[' then stack.push(c)
          when '}'
            return false unless stack.pop == '{'
          when ')'
            return false unless stack.pop == '('
          when ']'
            return false unless stack.pop == '['
          end
        end
        stack.empty?
      end

      def complete_statement?(code)
        # Check for valid statement termination
        code.strip.end_with?(';') ||
          code.strip.end_with?('}') ||
          code.strip.end_with?(')') ||
          code.strip.end_with?(']')
      end

      def process_buffer(buffer, history_file)
        Readline::HISTORY << buffer.strip
        run(buffer)
        File.open(history_file, 'a') { |f| f.puts(buffer) }
      rescue StandardError => e
        puts "[Error] #{e.message}".red
      end

      def load_history(file)
        return unless File.exist?(file)

        # Load last 100 lines of history
        lines = File.readlines(file).last(100).map(&:chomp)
        Readline::HISTORY.push(*lines)
      end

      def save_history(file)
        return unless Readline::HISTORY.any?

        # Save unique history entries
        history = Readline::HISTORY.to_a.uniq.last(100)
        File.write(file, "#{history.join("\n")}\n")
      end
    end
  end

  # ======================================================================
  # Section: Syntax Highlighter
  # Purpose: Contains methods to highlight Lox code syntax.
  # ======================================================================

  module SyntaxHighlighter
    unless defined?(TOKEN_COLORS)
      TOKEN_COLORS = {
        keyword: :cyan,
        string: :green,
        number: :yellow,
        identifier: :white,
        operator: :magenta,
        punctuation: :white
      }.freeze
    end
    unless defined?(TOKEN_COLORS)
      BRACKET_PAIRS = {
        '{' => '}', '}' => '{',
        '(' => ')', ')' => '(',
        '[' => ']', ']' => '['
      }.freeze
    end

    def self.highlight(code)
      analyzer = Lox::Lexical::Analyzer.new(code)
      tokens = analyzer.scan_tokens

      highlighted = []
      bracket_stack = []

      tokens.map do |token|
        color = case token.type
                when *Lox::Lexical::TokenType.constants.grep(/STRING|NUMBER/)
                  TOKEN_COLORS[token.type.to_s.downcase.to_sym]
                when *Lox::Lexical::TokenType.constants.grep(/IDENTIFIER/)
                  :identifier
                when *Lox::Lexical::TokenType.constants.grep(/EOF/)
                  nil
                when Lox::Lexical::TokenType::STRING then :green
                when Lox::Lexical::TokenType::NUMBER then :yellow
                when Lox::Lexical::TokenType::IDENTIFIER then :cyan
                when Lox::Lexical::TokenType::KEYWORD then :magenta
                else
                  :operator
                end

        # Check for bracket pairs
        if BRACKET_PAIRS.key?(token.lexeme)
          bracket_stack.push(token.lexeme)
          color = :blue
        elsif BRACKET_PAIRS.value?(token.lexeme)
          if BRACKET_PAIRS[token.lexeme] == bracket_stack.last
            bracket_stack.pop
            color = :blue
          else
            color = :red
          end
        end

        highlighted << token.lexeme.send(color)

        token.lexeme.send(color || :white)
      end.join(' ')
    rescue StandardError
      code # Fallback to uncolored code
    end
  end
end

Lox::Runner.main(ARGV) if $PROGRAM_NAME == __FILE__
