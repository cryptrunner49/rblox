module StringColors
  COLORS = {
    black:   "\e[30m",
    red:     "\e[31m",
    green:   "\e[32m",
    yellow:  "\e[33m",
    blue:    "\e[34m",
    magenta: "\e[35m",
    cyan:    "\e[36m",
    white:   "\e[37m",
    reset:   "\e[0m"
  }

  COLORS.each do |color, code|
    define_method(color) do
      "#{code}#{self}#{COLORS[:reset]}"
    end
  end
end

class String
  include StringColors
end
