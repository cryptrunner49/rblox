#!/usr/bin/env ruby
# frozen_string_literal: true

require 'benchmark'

require_relative '../src/lox/lexical/analyzer'
require_relative '../src/lox/syntax/parser'
require_relative '../src/lox/interpreter/expression_evaluator'

# Scripts to benchmark
SCRIPTS = {
  'Loop Test' => 'scripts/loop_test.lox',
  'Fibonacci Test' => 'scripts/fibonacci_test.lox',
  'Class Test' => 'scripts/class_test.lox',
  'Method Test' => 'scripts/method_test.lox',
  'Mixed Test' => 'scripts/mixed_test.lox'
}.freeze

Benchmark.bm(20) do |bm|
  SCRIPTS.each do |name, path|
    source = File.read(path)
    evaluator = Lox::Interpreter::ExpressionEvaluator.new

    # Measure scanning
    analyzer = Lox::Lexical::Analyzer.new(source)
    bm.report("#{name} - Scanning:") { analyzer.scan_tokens }

    # Measure parsing
    tokens = analyzer.scan_tokens
    parser = Lox::Syntax::Parser.new(tokens)
    bm.report("#{name} - Parsing:") { parser.parse }

    # Measure interpretation using parsed statements
    statements = parser.parse # Assign and use statements
    bm.report("#{name} - Interpreting:") { evaluator.interpret(statements) }
  end
end
