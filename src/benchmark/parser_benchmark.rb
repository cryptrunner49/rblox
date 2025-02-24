# frozen_string_literal: true

require 'benchmark'

require_relative '../lox/lexical/analyzer'
require_relative '../lox/syntax/parser'

source = File.read('./scripts/large_source_file.lox')
analyzer = Lox::Lexical::Analyzer.new(source)

Benchmark.bm do |bm|
  bm.report('Scanning tokens:') { analyzer.scan_tokens }
  tokens = analyzer.scan_tokens
  parser = Lox::Syntax::Parser.new(tokens)
  bm.report('Parsing:') { parser.parse }
end
