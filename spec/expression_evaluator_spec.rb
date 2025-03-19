# frozen_string_literal: true

require 'rspec'

require_relative '../src/lox/interpreter/environment'
require_relative '../src/lox/lexical/token'
require_relative '../src/lox/lexical/token_type'

module Spec
  RSpec.describe Lox::Interpreter::Environment do
    # ======================================================================
    # Section: Environment Tests
    # Purpose: Contains tests to verify the functionality of the environment.
    # ======================================================================

    let(:env) { Lox::Interpreter::Environment.new }
    let(:token) { Lox::Lexical::Token.new(Lox::Lexical::TokenType::IDENTIFIER, 'x', nil, 1) }

    context 'Variable Management' do
      it 'defines and retrieves a variable' do
        env.define('x', 42)
        expect(env.get(token)).to eq(42)
      end

      it 'assigns a new value to an existing variable' do
        env.define('x', 42)
        env.assign(token, 100)
        expect(env.get(token)).to eq(100)
      end

      it 'raises an error for undefined variable get' do
        expect { env.get(token) }.to raise_error(Lox::Interpreter::RuntimeError, "Undefined variable 'x'.")
      end
    end

    context 'Nested Scopes' do
      it 'retrieves a variable from an enclosing scope' do
        outer = Lox::Interpreter::Environment.new
        inner = Lox::Interpreter::Environment.new(outer)
        outer.define('x', 42)
        expect(inner.get(token)).to eq(42)
      end

      it 'shadows a variable in an inner scope' do
        outer = Lox::Interpreter::Environment.new
        inner = Lox::Interpreter::Environment.new(outer)
        outer.define('x', 42)
        inner.define('x', 100)
        expect(inner.get(token)).to eq(100)
        expect(outer.get(token)).to eq(42)
      end
    end
  end
end
