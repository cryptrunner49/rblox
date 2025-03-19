# spec/inheritance_spec.rb
# frozen_string_literal: true

require 'rspec'
require 'stringio'

require_relative '../src/lox/interpreter/expression_evaluator'
require_relative '../src/lox/syntax/parser'
require_relative '../src/lox/lexical/analyzer'

module Spec
  describe 'Inheritance' do
    # ======================================================================
    # Section: Inheritance Tests
    # Purpose: Contains tests to verify the functionality of inheritance.
    # ======================================================================

    let(:interpreter) { Lox::Interpreter::ExpressionEvaluator.new }
    let(:output) { StringIO.new }

    before do
      $stdout = output # Capture output
    end

    after do
      $stdout = STDOUT # Restore stdout
    end

    # Test basic inheritance
    it 'allows a class to inherit methods from a superclass' do
      program = <<~LOX
        class Animal {
          speak() {
            print "Animal speaks";
          }
        }

        class Dog < Animal {
          bark() {
            print "Woof!";
          }
        }

        var dog = Dog();
        dog.speak();
        dog.bark();
      LOX

      run_program(program, interpreter)
      expect(output.string.strip).to eq("Animal speaks\nWoof!")
    end

    # Test method overriding
    it 'allows a subclass to override methods from a superclass' do
      program = <<~LOX
        class Animal {
          speak() {
            print "Animal speaks";
          }
        }

        class Dog < Animal {
          speak() {
            print "Dog speaks";
          }
        }

        var animal = Animal();
        var dog = Dog();
        animal.speak();
        dog.speak();
      LOX

      run_program(program, interpreter)
      expect(output.string.strip).to eq("Animal speaks\nDog speaks")
    end

    # Test super keyword
    it 'allows a subclass to call superclass methods using super' do
      program = <<~LOX
        class Doughnut {
          cook() {
            print "Fry until golden brown.";
          }
        }

        class BostonCream < Doughnut {
          cook() {
            super.cook();
            print "Pipe full of custard and coat with chocolate.";
          }
        }

        BostonCream().cook();
      LOX

      run_program(program, interpreter)
      expect(output.string.strip).to eq("Fry until golden brown.\nPipe full of custard and coat with chocolate.")
    end

    # Test super binding across multiple levels
    it 'binds super to the parent of the class where the method is defined' do
      program = <<~LOX
        class A {
          method() {
            print "Method A";
          }
        }

        class B < A {
          method() {
            print "Method B";
          }
          test() {
            super.method();
          }
        }

        class C < B {}

        C().test();
      LOX

      run_program(program, interpreter)
      expect(output.string.strip).to eq('Method A')
    end

    # Test multiple levels of inheritance
    it 'allows subclasses to access superclass methods through multiple levels of inheritance' do
      program = <<~LOX
        class Grandparent {
          method() {
            print "Grandparent method";
          }
        }

        class Parent < Grandparent {
          method() {
            print "Parent method";
            super.method();
          }
        }

        class Child < Parent {
          method() {
            print "Child method";
            super.method();
          }
        }

        Child().method();
      LOX

      run_program(program, interpreter)
      expect(output.string.strip).to eq("Child method\nParent method\nGrandparent method")
    end

    private

    # Helper method to run Lox programs
    def run_program(source, interpreter)
      tokens = Lox::Lexical::Analyzer.new(source).scan_tokens
      statements = Lox::Syntax::Parser.new(tokens).parse
      interpreter.interpret(statements)
    end
  end
end
