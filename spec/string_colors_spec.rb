# frozen_string_literal: true

require 'rspec'

require_relative '../src/lox/utils/string_colors'

module Spec
  RSpec.describe Lox::Utils::StringColors do
    # ======================================================================
    # Section: String Colorization Tests
    # Purpose: Contains tests to verify the functionality of string colorization.
    # ======================================================================

    describe String do
      it 'colors a string red' do
        expect('test'.red).to eq("\e[31mtest\e[0m")
      end

      it 'colors a string green' do
        expect('test'.green).to eq("\e[32mtest\e[0m")
      end

      it 'resets color after application' do
        colored = 'test'.blue
        expect(colored).to end_with("\e[0m")
      end
    end
  end
end
