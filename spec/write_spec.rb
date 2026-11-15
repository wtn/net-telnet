# encoding: binary
require_relative 'fixtures/fake_socket'

describe "Net::Telnet#write" do
  it "sends the string without conversion" do
    socket = FakeTelnetSocket.new
    telnet_with(socket).write("a\n\xff")
    socket.written.should == "a\n\xff"
  end

  it "sends the whole string when the socket accepts a few bytes at a time" do
    socket = FakeTelnetSocket.new(max_write: 2)
    telnet_with(socket).write("abcdefg")
    socket.written.should == "abcdefg"
  end
end
