# frozen_string_literal: true

require_relative '../../../lib/commands/doctor'

RSpec.describe Raintron::Commands::Doctor do
  describe '#run' do
    it 'prints an OK message and does not exit when Preflight has no warnings' do
      allow(Raintron::Preflight).to receive(:check!)
      expect { described_class.run }.not_to raise_error
    end

    it 'prints the warning and exits(1) when Preflight warns' do
      allow(Raintron::Preflight).to receive(:check!) { warn 'missing toolkit' }

      expect { described_class.run }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end
  end
end
