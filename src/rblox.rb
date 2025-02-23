# frozen_string_literal: true

require_relative 'utils/string_colors'
require_relative 'lexical_analysis'

class Lox
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

      # Indicate an error in the exit code
      exit(65) if Lox.had_error
    end

    def run_prompt
      puts 'rblox 0.0.1'
      puts 'CTRL+C to quit'
      loop do
        print 'rblox>> '.red
        line = gets&.chomp
        break if line.nil? || line.empty?

        run(line)
        false
      end
    end

    def run(_source)
      # Placeholder for actual script execution logic
      # Scanner scanner = new Scanner(source);
      # List<token> tokens = scanner.scanTokens();

      # For now, just print the tokens
      # for (Token token : tokens) {
      #  System.out.println(token);
      # }
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

# Call main method with command-line arguments
# Lox.main(ARGV)

# Example Usage:
# Lox.error(10, 'Unexpected character')
# puts Lox.had_error # => true

la = LexicalAnalysis.new("2+2")
puts la.scan_tokens
