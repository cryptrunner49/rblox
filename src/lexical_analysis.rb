# frozen_string_literal: true

require_relative 'token'
require_relative 'token_type'

class LexicalAnalysis
  attr_reader :source, :tokens

  @keywords = {
    'and' => :AND,
    'class' => :CLASS,
    'else' => :ELSE,
    'false' => :FALSE,
    'for' => :FOR,
    'fun' => :FUN,
    'if' => :IF,
    'nil' => :NIL,
    'or' => :OR,
    'print' => :PRINT,
    'return' => :RETURN,
    'super' => :SUPER,
    'this' => :THIS,
    'true' => :TRUE,
    'var' => :VAR,
    'while' => :WHILE
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
    @tokens << Token.new(:EOF, '', nil, @line)
    @tokens
  end

  private

  def scan_token
    c = advance
    case c
    when '(' then add_token(:LEFT_PAREN)
    when ')' then add_token(:RIGHT_PAREN)
    when '{' then add_token(:LEFT_BRACE)
    when '}' then add_token(:RIGHT_BRACE)
    when ',' then add_token(:COMMA)
    when '.' then add_token(:DOT)
    when '-' then add_token(:MINUS)
    when '+' then add_token(:PLUS)
    when ';' then add_token(:SEMICOLON)
    when '*' then add_token(:STAR)
    when '!'
      add_token(match('=') ? :BANG_EQUAL : :BANG)
    when '='
      add_token(match('=') ? :EQUAL_EQUAL : :EQUAL)
    when '<'
      add_token(match('=') ? :LESS_EQUAL : :LESS)
    when '>'
      add_token(match('=') ? :GREATER_EQUAL : :GREATER)
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
        add_token(:SLASH)
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
      elsif isAlpha(c)
        identifier
      else
        Lox.error(@line, 'Unexpected character.')
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
      Lox.error(@line, 'Unterminated string.')
      return
    end

    # Consume the closing quote.
    advance

    # Extract the string value without the surrounding quotes.
    value = @source[@start + 1...@current - 1]
    add_token(:STRING, value)
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
    add_token(:NUMBER, value)
  end

  def identifier
    advance while alpha_numeric?(peek)

    text = @source[@start...@current]
    type = @keywords[text] || :IDENTIFIER
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
