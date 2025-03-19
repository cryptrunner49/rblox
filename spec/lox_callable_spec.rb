# frozen_string_literal: true

require 'rspec'

require_relative '../src/lox/interpreter/lox_callable'

module Spec
  RSpec.describe Lox::Interpreter::LoxCallable do
    # ======================================================================
    # Section: LoxCallable Tests
    # Purpose: Contains tests to verify the functionality of LoxCallable.
    # ======================================================================

    let(:callable_class) do
      Class.new do
        include Lox::Interpreter::LoxCallable
      end
    end

    it 'raises NotImplementedError for arity when not defined' do
      instance = callable_class.new
      expect do
        instance.arity
      end.to raise_error(NotImplementedError, "Classes including LoxCallable must implement 'arity'")
    end

    it 'raises NotImplementedError for call when not defined' do
      instance = callable_class.new
      expect do
        instance.call(nil,
                       [])
      end.to raise_error(NotImplementedError,
                          "Classes including LoxCallable must implement 'call(interpreter, arguments)'")
    end
  end
end
