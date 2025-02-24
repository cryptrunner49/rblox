#!/usr/bin/env ruby

require 'readline'

require_relative 'lexical/analyzer'
require_relative 'lexical/token_type'
require_relative 'syntax/parser'
require_relative 'syntax/expr'
require_relative 'interpreter/expression_evaluator'
require_relative 'utils/string_colors'
require_relative '../../generator/ast_printer'

module Lox
  module SyntaxHighlighter
    TOKEN_COLORS = {
      keyword: :cyan,
      string: :green,
      number: :yellow,
      identifier: :white,
      operator: :magenta,
      punctuation: :white
    }.freeze
  
    def self.highlight(code)
      analyzer = Lox::Lexical::Analyzer.new(code)
      tokens = analyzer.scan_tokens
      
      tokens.map do |token|
        color = case token.type
        when *Lox::Lexical::TokenType.constants.grep(/STRING|NUMBER/)
          TOKEN_COLORS[token.type.to_s.downcase.to_sym]
        when *Lox::Lexical::TokenType.constants.grep(/IDENTIFIER/)
          :identifier
        when *Lox::Lexical::TokenType.constants.grep(/EOF/)
          nil
        else
          :operator
        end
        
        token.lexeme.send(color || :white)
      end.join(' ')
    rescue => e
      code # Fallback to uncolored code
    end
  end

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
        puts 'rblox 0.0.1'.cyan
        puts 'CTRL+C or CTRL+D (CTRL+Z on Windows) to quit'
        history_file = File.expand_path('~/.rblox_history')
        load_history(history_file)

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
        indent_level = 0
        in_multiline = false
      
        begin
          loop do
            line = Readline.readline(prompt, true)
            break if line.nil? || line.match(/^\s*(exit|quit)!?$/)

            # Display syntax-highlighted input
    puts "\e[1A\e[K#{SyntaxHighlighter.highlight(line)}" if ENV['TERM'] != 'dumb'
      
            if line.strip.empty?
              buffer = ''
              next
            end
      
            buffer << line << "\n"
            indent_level += line.count('{') - line.count('}')
            
            if balanced_braces?(buffer) && complete_statement?(buffer)
              process_buffer(buffer, history_file)
              buffer = ''
              prompt = 'rblox>> '.red
              indent_level = 0
            else
              prompt = ('  ' * [indent_level, 0].max) + '... '.yellow
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

      def process_buffer(buffer, history_file)
        if buffer.strip == '?help'
          show_help
          return
        end
        # ... existing processing ...
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
          
        Language Features:
          - Full Lox language support
          - Multiline input with automatic continuation
          - Syntax highlighting
          - Context-aware autocomplete
        HELP
      end

      def run(source)
        #puts "Processing source: #{source}"
        analyzer = Lexical::Analyzer.new(source)
        tokens = analyzer.scan_tokens
        #puts "Tokens: #{tokens.map(&:to_s)}"

        parser = Syntax::Parser.new(tokens)
        statements = parser.parse

        if statements.nil?
          puts "[Parse Error] Invalid syntax detected"
          @had_error = true
          return
        end

        #puts 'Statements parsed:'
        #statements.each { |stmt| puts Generator::AstPrinter.new.print(stmt) }

        # Use a persistent interpreter instance.
        @interpreter ||= Interpreter::ExpressionEvaluator.new
        begin
          @interpreter.interpret(statements)
        rescue Lox::RuntimeError => e
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

      private

def balanced_braces?(code)
  code.count('{') == code.count('}')
end

def complete_statement?(code)
  code.strip.end_with?(';') || code.strip.end_with?('}')
end

def process_buffer(buffer, history_file)
  Readline::HISTORY << buffer.strip
  run(buffer)
  File.open(history_file, 'a') { |f| f.puts(buffer) }
rescue => e
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
  File.write(file, history.join("\n") + "\n")
end

      #def report(line, where, message)
      #  source_line = @source.split("\n")[line - 1]
      #  warn "[line #{line}] Error#{where}: #{message}"
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

Lox::Runner.main(ARGV) if $PROGRAM_NAME == __FILE__