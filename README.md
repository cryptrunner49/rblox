# Implementation of the Lox Language in Ruby

## Running the REPL

Requires Ruby version 3.3.6  

Make sure Ruby 3.3.6 is installed before running the command below:

```
bundle install
ruby src/lox/runner.rb
```

## Testing

```
bundle install
bundle exec rspec
```

## Project Structure

```ruby
generator/ -> Directory for development utilities, not runtime components; helps in generating and debugging AST structures.

scripts/ -> Directory for Lox script files used to test interpreter functionality manually or as input for `runner.rb`.

benchmark/ -> Directory for benchmark scripts or tools to measure interpreter performance.

spec/ -> Directory for automated tests using RSpec, ensuring interpreter correctness and regression checking.

src/lox/interpreter/ -> Directory for runtime components; handles interpretation, variable management, and resolution.

src/lox/lexical/ -> Directory for tokenization; converts source code into a stream of tokens (scanner).

src/lox/syntax/ -> Directory for parsing and AST representation; builds the syntax tree from tokens.

src/lox/utils/ -> Directory for miscellaneous utilities; supports features like REPL coloring or debugging output.

src/lox/runner.rb
    - Orchestrates the overall process: tokenizes input, parses into AST, resolves variables, and executes via `ExpressionEvaluator`.
    - Handles both REPL and file execution modes, managing user interaction and error reporting.
```

## Language features

- tokens and lexing
- abstract syntax trees
- recursive descent parsing
- prefix and infix expressions
- runtime representation of objects
- interpreting code using the Visitor pattern
- lexical scope
- environment chains for storing variables
- control flow
- functions with parameters
- closures
- static variable resolution and error detection
- classes
- constructors
- fields
- methods
- inheritance
