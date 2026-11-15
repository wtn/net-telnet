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

  it "sends a bare CR as CR NUL" do
    @telnet.print("a\rb")
    @socket.written.should == "a\r\0b"
  end

  it "sends CR LF as a single newline" do
    @telnet.print("ls\r\n")
    @socket.written.should == "ls\r\n"
  end

  it "sends a bare CR unchanged after the host requests BINARY" do
    @telnet.preprocess("\xff\xfd\x00")
    @socket.clear
    @telnet.print("a\rb")
    @socket.written.should == "a\rb"
  end

  it "sends a UTF-8 string as its bytes" do
    @telnet.print("caf\xc3\xa9\n".force_encoding("UTF-8"))
    @socket.written.should == "caf\xc3\xa9\r\n"
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

  it "stops sending a newline as CR after the host revokes BINARY" do
    @telnet.preprocess("\xff\xfb\x03\xff\xfd\x00\xff\xfe\x00")
    @socket.clear
    @telnet.print("ls\n")
    @socket.written.should == "ls\r\0"
  end
end

describe "Net::Telnet#puts with default options" do
  it "appends a newline and sends it as CR LF" do
    socket = FakeTelnetSocket.new
    telnet_with(socket).puts("ls")
    socket.written.should == "ls\r\n"
  end

  it "sends a UTF-8 string as its bytes" do
    socket = FakeTelnetSocket.new
    telnet_with(socket).puts("caf\xc3\xa9".force_encoding("UTF-8"))
    socket.written.should == "caf\xc3\xa9\r\n"
  end
end

describe "Net::Telnet#print when Telnetmode is false" do
  before(:each) do
    @socket = FakeTelnetSocket.new
    @telnet = telnet_with(@socket, "Telnetmode" => false)
  end

  it "sends a bare CR unchanged" do
    @telnet.print("a\rb")
    @socket.written.should == "a\rb"
  end

  it "sends newlines and CR LF as CR LF" do
    @telnet.print("a\nb\r\n")
    @socket.written.should == "a\r\nb\r\n"
  end
end
