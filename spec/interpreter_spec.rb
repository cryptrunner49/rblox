# frozen_string_literal: true

require 'rspec'
require 'stringio'

require_relative '../src/lox/runner'

module Spec
  RSpec.describe Lox::Runner do
    def capture_stdout
      original_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original_stdout
    end

    context 'Nested Block Scoping and Variable Shadowing' do
      it 'correctly handles nested blocks with variable shadowing' do
        source = <<~LOX
          var x = "outer";
          {
            var x = "inner";
            print x;
          }
          print x;
        LOX
        output = capture_stdout { Lox::Runner.run(source) }
        expect(output).to include('inner')
        expect(output).to include('outer')
      end
    end

    context 'Operator Precedence' do
      it 'evaluates 1 + 2 * 3 with multiplication taking precedence' do
        source = 'print 1 + 2 * 3;'
        output = capture_stdout { Lox::Runner.run(source) }
        expect(output).to include('7')
      end

      it 'evaluates (1 + 2) * 3 with parentheses altering precedence' do
        source = 'print (1 + 2) * 3;'
        output = capture_stdout { Lox::Runner.run(source) }
        expect(output).to include('9')
      end
    end
  end
end
