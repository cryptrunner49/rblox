#!/usr/bin/env ruby
# frozen_string_literal: true

require 'benchmark'

require_relative '../src/lox/lexical/analyzer'
require_relative '../src/lox/syntax/parser'

source = File.read('scripts/fun_test.lox')
analyzer = Lox::Lexical::Analyzer.new(source)

Benchmark.bm do |bm|
  bm.report('Scanning tokens:') { analyzer.scan_tokens }
  tokens = analyzer.scan_tokens
  parser = Lox::Syntax::Parser.new(tokens)
  bm.report('Parsing:') { parser.parse }
end
