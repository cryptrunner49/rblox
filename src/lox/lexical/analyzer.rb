# frozen_string_literal: true

require_relative 'token'
require_relative 'token_type'

module Lox
  module Lexical
    class Analyzer
      attr_reader :source, :tokens

      @keywords = {
        'and' => TokenType::AND,
        'class' => TokenType::CLASS,
        'else' => TokenType::ELSE,
        'false' => TokenType::FALSE,
        'for' => TokenType::FOR,
        'fun' => TokenType::FUN,
        'if' => TokenType::IF,
        'nil' => TokenType::NIL,
        'or' => TokenType::OR,
        'print' => TokenType::PRINT,
        'return' => TokenType::RETURN,
        'super' => TokenType::SUPER,
        'this' => TokenType::THIS,
        'true' => TokenType::TRUE,
        'var' => TokenType::VAR,
        'while' => TokenType::WHILE
      }

      def initialize(source)
        @source = source
        @tokens = []
        @start = 0
        @current = 0
        @line = 1
      end

      def scan_tokens
        until at_end?
          # We are at the beginning of the next lexeme.
          @start = @current
          scan_token
        end
        @tokens << Token.new(TokenType::EOF, '', nil, @line)
        @tokens
      end

      private

      def scan_token
        c = advance
        case c
        when '(' then add_token(TokenType::LEFT_PAREN)
        when ')' then add_token(TokenType::RIGHT_PAREN)
        when '{' then add_token(TokenType::LEFT_BRACE)
        when '}' then add_token(TokenType::RIGHT_BRACE)
        when ',' then add_token(TokenType::COMMA)
        when '.' then add_token(TokenType::DOT)
        when '-' then add_token(TokenType::MINUS)
        when '+' then add_token(TokenType::PLUS)
        when ';' then add_token(TokenType::SEMICOLON)
        when '*' then add_token(TokenType::STAR)
        when '!'
          add_token(match('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
        when '='
          add_token(match('=') ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
        when '<'
          add_token(match('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
        when '>'
          add_token(match('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
        when '/'
          if match('/')
            # A single-line comment goes until the end of the line.
            advance while peek != "\n" && !at_end?
          elsif match('*')
            # A block comment goes until we find '*/'
            while peek != '*' || peek_next != '/' && !at_end?
              advance
              @line += 1 if peek == "\n" # Keep track of new lines
            end
            unless at_end?
              advance # Consume '*'
              advance # Consume '/'
            end
          else
            add_token(TokenType::SLASH)
          end
        when ' ', "\r", "\t"
          # Ignore whitespace
        when "\n"
          @line += 1
        when '"'
          string
        else
          if digit?(c)
            number
          elsif alpha?(c)
            identifier
          else
            Lox::Interpreter.error(@line, 'Unexpected character.')
          end
        end
      end

      def match(expected)
        return false if at_end?
        return false if @source[@current] != expected

        @current += 1
        true
      end

      def string
        while peek != '"' && !at_end?
          @line += 1 if peek == "\n"
          advance
        end

        if at_end?
          Lox::Interpreter.error(@line, 'Unterminated string.')
          return
        end

        # Consume the closing quote.
        advance

        # Extract the string value without the surrounding quotes.
        value = @source[@start + 1...@current - 1]
        add_token(TokenType::STRING, value)
      end

      def peek
        return "\0" if at_end?

        @source[@current]
      end

      def digit?(c)
        c >= '0' && c <= '9'
      end

      def at_end?
        @current >= @source.length
      end

      def advance
        @current += 1
        @source[@current - 1]
      end

      def add_token(type, literal = nil)
        text = @source[@start...@current]
        @tokens << Token.new(type, text, literal, @line)
      end

      def number
        advance while digit?(peek)

        # Look for a fractional part.
        if peek == '.' && digit?(peek_next)
          # Consume the "."
          advance
          advance while digit?(peek)
        end

        # Add the token as a number
        value = @source[@start...@current].to_f
        add_token(TokenType::NUMBER, value)
      end

      def identifier
        advance while alpha_numeric?(peek)

        text = @source[@start...@current]
        type = @keywords[text] || TokenType::IDENTIFIER
        add_token(type)
      end

      def alpha?(c)
        ('a'..'z').include?(c) || ('A'..'Z').include?(c) || c == '_'
      end

      def alpha_numeric?(c)
        alpha?(c) || digit?(c)
      end

      def peek_next
        return "\0" if @current + 1 >= @source.length

        @source[@current + 1]
      end
    end
  end
end
