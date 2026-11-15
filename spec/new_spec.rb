# encoding: binary
require_relative 'fixtures/fake_socket'
require 'ipaddr'

describe "Net::Telnet.new without a Proxy" do
  before(:each) do
    @socket = FakeTelnetSocket.new
  end

  it "yields connection messages that name the host" do
    TCPSocket.should_receive(:open).and_return(@socket)
    messages = []
    Net::Telnet.new("Host" => "example.test", "Timeout" => false) { |m| messages << m }
    messages.should == ["Trying example.test...\n", "Connected to example.test.\n"]
  end

  it "accepts a Host that is not a String" do
    TCPSocket.should_receive(:open).with("127.0.0.1", 23).and_return(@socket)
    messages = []
    Net::Telnet.new("Host" => IPAddr.new("127.0.0.1"), "Timeout" => false) { |m| messages << m }
    messages.should == ["Trying 127.0.0.1...\n", "Connected to 127.0.0.1.\n"]
  end

  unless Net::Telnet::OPEN_TIMEOUT_SUPPORTED
    it "raises Net::OpenTimeout when the connection is not opened in time" do
      def TCPSocket.open(*args)
        sleep 1
      end
      begin
        lambda {
          Net::Telnet.new("Host" => "example.test", "Timeout" => 0.1)
        }.should raise_error(Net::OpenTimeout)
      ensure
        TCPSocket.singleton_class.send(:remove_method, :open)
      end
    end
  end

  if Net::Telnet::OPEN_TIMEOUT_SUPPORTED
    it "passes Timeout to TCPSocket.open as open_timeout" do
      TCPSocket.should_receive(:open).with("example.test", 23, open_timeout: 5).and_return(@socket)
      Net::Telnet.new("Host" => "example.test", "Timeout" => 5)
    end

    it "raises Net::OpenTimeout when TCPSocket.open times out" do
      TCPSocket.should_receive(:open).and_raise(IO::TimeoutError.new("user specified timeout"))
      lambda {
        Net::Telnet.new("Host" => "example.test", "Timeout" => 5)
      }.should raise_error(Net::OpenTimeout)
    end
  end
end
