# encoding: binary
require_relative 'fixtures/fake_socket'

describe "Net::Telnet#print with default options" do
  before(:each) do
    @socket = FakeTelnetSocket.new
    @telnet = telnet_with(@socket)
  end

  it "sends a newline as CR LF" do
    @telnet.print("ls\n")
    @socket.written.should == "ls\r\n"
  end

  it "doubles IAC" do
    @telnet.print("a\xffb")
    @socket.written.should == "a\xff\xffb"
  end

  it "sends a newline as CR NUL after the host enables SGA" do
    @telnet.preprocess("\xff\xfb\x03")
    @socket.clear
    @telnet.print("ls\n")
    @socket.written.should == "ls\r\0"
  end

  it "sends a newline as CR after the host enables SGA and requests BINARY" do
    @telnet.preprocess("\xff\xfb\x03\xff\xfd\x00")
    @socket.clear
    @telnet.print("ls\n")
    @socket.written.should == "ls\r"
  end
end

describe "Net::Telnet#puts with default options" do
  it "appends a newline and sends it as CR LF" do
    socket = FakeTelnetSocket.new
    telnet_with(socket).puts("ls")
    socket.written.should == "ls\r\n"
  end
end
