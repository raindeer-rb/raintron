# frozen_string_literal: true

require_relative '../../../lib/cli/cli'

RSpec.describe Raintron::CLI do
  describe '.run' do
    it 'prints usage and exits(1) for an empty argv' do
      expect { described_class.run([]) }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end

    it 'prints an unknown-command message and exits(1) for an unrecognized verb' do
      expect { described_class.run(['bogus']) }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end

    it 'routes "install" to Commands::Install with the remaining argv, unsplit' do
      expect(Raintron::Commands::Install).to receive(:run).with(argv: ['demo', '--force'])
      described_class.run(['install', 'demo', '--force'])
    end

    it 'routes "press" to Commands::Press with the remaining argv' do
      expect(Raintron::Commands::Press).to receive(:run).with(argv: ['--ruby', '3.4.2'])
      described_class.run(['press', '--ruby', '3.4.2'])
    end

    it 'routes "icons" to Commands::Icons with the remaining argv' do
      expect(Raintron::Commands::Icons).to receive(:run).with(argv: [])
      described_class.run(['icons'])
    end

    it 'routes "doctor" to Commands::Doctor with no arguments' do
      expect(Raintron::Commands::Doctor).to receive(:run)
      described_class.run(['doctor'])
    end

    it 'does not split a flag+value pair across positional/flag handling (regression check)' do
      # A naive "starts with -" split would misroute the "1000" value token as a
      # second positional argument, breaking trees' single-token verb match.
      expect(Raintron::Commands::Install).to receive(:run).with(argv: ['demo', '--width', '1000'])
      described_class.run(['install', 'demo', '--width', '1000'])
    end
  end
end
