require_relative 'utils/string_colors'

class Lox
  def main(args)
    if args.length > 1
      puts "Usage: rblox [scipt]"
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
  end

  def run_prompt
    puts "rblox 0.0.1"
    puts "CTRL+C to quit"
    loop do
      print "rblox>> ".red
      line = gets&.chomp
      break if line.nil? || line.empty?
      run(line)
    end
  end

  def run(_source)
    # Placeholder for actual script execution logic
  end
end

# Call main method with command-line arguments
#Lox.main(ARGV)
lox = Lox.new
lox.main(ARGV)