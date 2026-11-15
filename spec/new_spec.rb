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
end
