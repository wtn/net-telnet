# encoding: binary
require_relative 'fixtures/fake_socket'

describe "Net::Telnet#preprocess with default options" do
  before(:each) do
    @socket = FakeTelnetSocket.new
    @telnet = telnet_with(@socket)
  end

  it "leaves plain text unchanged" do
    @telnet.preprocess("hello world").should == "hello world"
    @socket.written.should == ""
  end

  it "converts CR LF to a newline" do
    @telnet.preprocess("a\r\nb").should == "a\nb"
  end

  it "converts CR NUL to CR" do
    @telnet.preprocess("a\r\0b").should == "a\rb"
  end

  it "removes a NUL that does not follow CR" do
    @telnet.preprocess("a\0b").should == "ab"
  end

  it "converts IAC IAC to a single 255 byte" do
    @telnet.preprocess("a\xff\xffb").should == "a\xffb"
    @socket.written.should == ""
  end

  it "treats the byte after an escaped IAC as data" do
    @telnet.preprocess("\xff\xff\xfb\x01").should == "\xff\xfb\x01"
    @socket.written.should == ""
  end

  it "keeps the data around a command" do
    @telnet.preprocess("ab\xff\xf1cd").should == "abcd"
  end

  {
    "NOP" => "\xf1", "DM" => "\xf2", "BRK" => "\xf3", "IP" => "\xf4",
    "AO" => "\xf5", "EC" => "\xf7", "EL" => "\xf8", "GA" => "\xf9",
    "EOR" => "\xef", "ABORT" => "\xee", "SUSP" => "\xed", "EOF" => "\xec",
  }.each do |name, byte|
    it "removes IAC #{name} from the data" do
      @telnet.preprocess("a\xff#{byte}b").should == "ab"
      @socket.written.should == ""
    end
  end

  it "answers IAC AYT and removes it from the data" do
    @telnet.preprocess("a\xff\xf6b").should == "ab"
    @socket.written.should_not == ""
  end

  it "answers IAC DO BINARY with IAC WILL BINARY" do
    @telnet.preprocess("\xff\xfd\x00").should == ""
    @socket.written.should == "\xff\xfb\x00"
  end

  {
    "ECHO" => 1, "SGA" => 3, "TTYPE" => 24, "NAWS" => 31,
    "NEW-ENVIRON" => 39, "COM-PORT" => 44, "option 200" => 200,
  }.each do |name, code|
    it "answers IAC DO #{name} with IAC WONT #{name}" do
      @telnet.preprocess("a\xff\xfd#{code.chr}b").should == "ab"
      @socket.written.should == "\xff\xfc#{code.chr}"
    end
  end

  { "BINARY" => 0, "ECHO" => 1, "SGA" => 3 }.each do |name, code|
    it "answers IAC WILL #{name} with IAC DO #{name}" do
      @telnet.preprocess("\xff\xfb#{code.chr}").should == ""
      @socket.written.should == "\xff\xfd#{code.chr}"
    end
  end

  { "TTYPE" => 24, "COM-PORT" => 44, "option 200" => 200 }.each do |name, code|
    it "answers IAC WILL #{name} with IAC DONT #{name}" do
      @telnet.preprocess("a\xff\xfb#{code.chr}b").should == "ab"
      @socket.written.should == "\xff\xfe#{code.chr}"
    end
  end

  it "answers IAC WONT SGA with IAC DONT SGA after SGA was enabled" do
    @telnet.preprocess("\xff\xfb\x03")
    @socket.clear
    @telnet.preprocess("\xff\xfc\x03").should == ""
    @socket.written.should == "\xff\xfe\x03"
  end

  it "removes a subnegotiation" do
    @telnet.preprocess("a\xff\xfa\x18\x01\xff\xf0b").should == "ab"
  end

  it "removes a subnegotiation that contains an escaped IAC" do
    @telnet.preprocess("a\xff\xfa\x18\xff\xff\x01\xff\xf0b").should == "ab"
  end
end
