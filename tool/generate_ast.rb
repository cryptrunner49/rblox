
module Generator
  class GenerateAst
    def self.main
      if ARGV.length != 1
        STDERR.puts "Usage: generate_ast <output directory>"
        exit 64
      end
      output_dir = ARGV[0]
      define_ast(output_dir, 'Expr', [
        'Binary : Expr left, Token operator, Expr right',
        'Grouping : Expr expression',
        'Literal : Object value',
        'Unary : Token operator, Expr right'
      ])
    end

    def define_ast(output_dir, base_name, types)
      path = "#{output_dir}/#{base_name.downcase}.rb"
      File.open(path, "w") do |file|
        file.puts "# #{base_name.downcase}.rb"
        file.puts
        file.puts "module Lox"
        file.puts "  class #{base_name}"
    
        # Define the Visitor module inside Expr
        define_visitor(file, base_name, types)
    
        # Define the accept method in the base class
        file.puts "    def accept(visitor)"
        file.puts "      raise NotImplementedError, \"Subclasses must implement accept\""
        file.puts "    end"
        file.puts
    
        # Define each subclass
        types.each do |type|
          class_name, fields = type.split(":").map(&:strip)
          define_type(file, base_name, class_name, fields)
        end
    
        file.puts "  end"  # end of class Expr
        file.puts "end"  # end of module Lox
      end
    end
    
    def define_type(file, base_name, class_name, field_list)
      file.puts "    class #{class_name} < #{base_name}"
      fields = field_list.split(", ")
      fields.each do |field|
        type, name = field.split(" ")
        file.puts "      # @#{name} : #{type}"
      end
      attr_names = fields.map { |field| field.split(" ").last }
      file.puts "      attr_reader :#{attr_names.join(", :")}"
      file.puts
      file.puts "      def initialize(#{attr_names.join(", ")})"
      attr_names.each do |name|
        file.puts "        @#{name} = #{name}"
      end
      file.puts "      end"
      file.puts
      file.puts "      def accept(visitor)"
      file.puts "        visitor.visit_#{class_name.downcase}_#{base_name.downcase}(self)"
      file.puts "      end"
      file.puts "    end"
      file.puts
    end
    
    def define_visitor(file, base_name, types)
      file.puts "    module Visitor"
      types.each do |type|
        type_name = type.split(":")[0].strip
        method_name = "visit_#{type_name.downcase}_#{base_name.downcase}"
        file.puts "      def #{method_name}(expr)"
        file.puts "        raise NotImplementedError, \"Must implement #{method_name}\""
        file.puts "      end"
        file.puts
      end
      file.puts "    end"
      file.puts
    end
  end

  GenerateAst.main if __FILE__ == $0
end