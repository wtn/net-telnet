require_relative '../lib/net/telnet'
require_relative 'fixtures/fake_socket'

describe "Net::Telnet#waitfor when Telnetmode is false and Binmode is false" do
  before(:each) do
    @socket = Object.new
    def @socket.kind_of?(klass)
      klass == IO
    end
    def @socket.chunks=(chunks)
      @chunks = chunks
    end
    def @socket.wait_readable(timeout = nil)
      @chunks.empty? ? nil : self
    end
    def @socket.readpartial(maxlen)
      raise EOFError if @chunks.empty?
      @chunks.shift
    end
    @telnet = Net::Telnet.new("Proxy" => @socket, "Telnetmode" => false)
  end

  it "keeps a CR at the end of a chunk when the next chunk does not start with LF" do
    @socket.chunks = ["abc\r", "def"]
    @telnet.waitfor(/def/).should == "abc\rdef"
  end

  it "converts a CR+LF split across chunks into a newline" do
    @socket.chunks = ["abc\r", "\ndef"]
    @telnet.waitfor(/def/).should == "abc\ndef"
  end

  it "yields the data without the held-back CR until the next chunk arrives" do
    @socket.chunks = ["abc\r", "\ndef"]
    yielded = []
    @telnet.waitfor(/def/) { |c| yielded << c }
    yielded.should == ["abc", "\ndef"]
  end
end

describe "Net::Telnet#waitfor when Telnetmode is false and Binmode is true" do
  before(:each) do
    @socket = Object.new
    def @socket.kind_of?(klass)
      klass == IO
    end
    def @socket.chunks=(chunks)
      @chunks = chunks
    end
    def @socket.wait_readable(timeout = nil)
      @chunks.empty? ? nil : self
    end
    def @socket.readpartial(maxlen)
      raise EOFError if @chunks.empty?
      @chunks.shift
    end
    @telnet = Net::Telnet.new("Proxy" => @socket, "Telnetmode" => false, "Binmode" => true)
  end

  it "yields each chunk unchanged, including a trailing CR" do
    @socket.chunks = ["abc\r", "def"]
    yielded = []
    @telnet.waitfor(/def/) { |c| yielded << c }.should == "abc\rdef"
    yielded.should == ["abc\r", "def"]
  end
end

describe "Net::Telnet#waitfor when Telnetmode is false and Binmode is false, across calls" do
  it "keeps a CR LF split across two waitfor calls" do
    socket = FakeTelnetSocket.new("abc\r")
    telnet = telnet_with(socket, "Telnetmode" => false)
    telnet.waitfor(/abc/).should == "abc"
    socket.feed("\ndef")
    telnet.waitfor(/def/).should == "\ndef"
  end

  it "returns a trailing CR received just before EOF" do
    socket = FakeTelnetSocket.new("abc\r", :eof)
    telnet_with(socket, "Telnetmode" => false).waitfor(/zzz/).should == "abc\r"
  end
end
