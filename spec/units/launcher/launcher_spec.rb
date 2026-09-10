# frozen_string_literal: true

RSpec.describe Raintron::Launcher do
  after { ENV.delete('RAINTRON_APP_ROOT') }

  describe '#start_server' do
    it 'sets RAINTRON_APP_ROOT before forking, so the child (and PwdOverride) inherit it' do
      launcher = described_class.new(title: 'Test', app_root: '/tmp/some_app') { nil }
      seen_app_root = nil
      allow(launcher).to receive(:fork) do
        seen_app_root = ENV.fetch('RAINTRON_APP_ROOT', nil)
        42
      end

      launcher.start_server

      expect(seen_app_root).to eq('/tmp/some_app')
    end

    it 'runs the server block inside the forked child, after applying shims' do
      ran_block = false
      launcher = described_class.new(title: 'Test', app_root: '/tmp/some_app') { ran_block = true }
      allow(launcher).to receive(:fork) do |&block|
        block.call
        42
      end
      allow(Raintron::Shims).to receive(:apply!)
      allow(Raintron).to receive(:packed?).and_return(false)

      launcher.start_server

      expect(ran_block).to be true
      expect(Raintron::Shims).to have_received(:apply!).with(packed: false)
    end

    it 'does not require webview_ruby (that only happens in #open_window, in the parent)' do
      launcher = described_class.new(title: 'Test', app_root: '/tmp/some_app') { nil }
      allow(launcher).to receive(:fork).and_return(42)

      launcher.start_server

      expect($LOADED_FEATURES.grep(/webview_ruby/)).to be_empty
    end
  end

  describe '#stop_server' do
    it 'sends TERM and waits for the pid' do
      launcher = described_class.new(title: 'Test') { nil }
      launcher.instance_variable_set(:@pid, 123)
      allow(Process).to receive(:kill).with('TERM', 123)
      allow(Process).to receive(:wait).with(123)

      launcher.stop_server

      expect(Process).to have_received(:kill).with('TERM', 123)
      expect(Process).to have_received(:wait).with(123)
    end

    it 'is a no-op if the server was never started' do
      launcher = described_class.new(title: 'Test') { nil }
      expect { launcher.stop_server }.not_to raise_error
    end

    it 'swallows Errno::ESRCH (process already gone)' do
      launcher = described_class.new(title: 'Test') { nil }
      launcher.instance_variable_set(:@pid, 123)
      allow(Process).to receive(:kill).and_raise(Errno::ESRCH)

      expect { launcher.stop_server }.not_to raise_error
    end

    it 'swallows Errno::ECHILD (already reaped)' do
      launcher = described_class.new(title: 'Test') { nil }
      launcher.instance_variable_set(:@pid, 123)
      allow(Process).to receive(:kill)
      allow(Process).to receive(:wait).and_raise(Errno::ECHILD)

      expect { launcher.stop_server }.not_to raise_error
    end
  end

  describe '#wait_for_port' do
    it 'returns once the port accepts a connection' do
      server = TCPServer.new('127.0.0.1', 0)
      launcher = described_class.new(title: 'Test', host: '127.0.0.1', port: server.addr[1]) { nil }

      expect { launcher.wait_for_port }.not_to raise_error
    ensure
      server&.close
    end

    it 'eventually gives up (Timeout::Error) if nothing is ever listening' do
      launcher = described_class.new(title: 'Test', host: '127.0.0.1', port: 1) { nil }
      allow(Timeout).to receive(:timeout).with(10).and_raise(Timeout::Error)

      expect { launcher.wait_for_port }.to raise_error(Timeout::Error)
    end
  end
end
