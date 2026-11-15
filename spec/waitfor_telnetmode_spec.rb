# encoding: binary
require_relative 'fixtures/fake_socket'

describe "Net::Telnet#waitfor with default options" do
  def receive(chunks)
    socket = FakeTelnetSocket.new(*chunks)
    data = telnet_with(socket).waitfor(/\$ \z/n)
    [data, socket.written]
  rescue => e
    [e.class, socket.written]
  end

  # Each stream ends in the prompt "$ ".  [stream, expected data, expected replies]
  [
    ["a\r\nb$ ", "a\nb$ ", ""],
    ["a\r\0b$ ", "a\rb$ ", ""],
    ["a\xff\xffb$ ", "a\xffb$ ", ""],
    ["a\xff\xff\xfbb$ ", "a\xff\xfbb$ ", ""],
    ["a\xff\xff\xff\xfd\x18b$ ", "a\xffb$ ", "\xff\xfc\x18"],
    ["a\xff\xf1b$ ", "ab$ ", ""],
    ["a\xff\xf9b$ ", "ab$ ", ""],
    ["a\xff\xfd\x18b$ ", "ab$ ", "\xff\xfc\x18"],
    ["a\xff\xfb\x01b$ ", "ab$ ", "\xff\xfd\x01"],
    ["a\xff\xfa\x18\x01\xff\xf0b$ ", "ab$ ", ""],
  ].each do |stream, data, replies|
    it "handles #{stream.inspect} the same way at every split point" do
      failures = (1...stream.bytesize).map do |i|
        got = receive([stream.byteslice(0, i), stream.byteslice(i..-1)])
        [i, *got] unless got == [data, replies]
      end
      failures.compact.should == []
    end

    it "handles #{stream.inspect} delivered one byte at a time" do
      receive(stream.each_char.to_a).should == [data, replies]
    end
  end

  it "removes a subnegotiation that arrives in several chunks" do
    receive(["abc\xff\xfa\x18", "\x01", "\xff\xf0x$ "]).should == ["abcx$ ", ""]
  end

  it "returns nil and yields nil at EOF when no data was received" do
    socket = FakeTelnetSocket.new(:eof)
    yielded = []
    telnet_with(socket).waitfor(/\$ \z/n) { |c| yielded << c }.should == nil
    yielded.should == [nil]
  end

  it "raises EOFError at EOF when FailEOF is set" do
    socket = FakeTelnetSocket.new("partial", :eof)
    lambda {
      telnet_with(socket).waitfor("Match" => /\$ \z/n, "FailEOF" => true)
    }.should raise_error(EOFError)
  end

  it "raises Net::ReadTimeout when the match is not seen" do
    socket = FakeTelnetSocket.new("no prompt here")
    lambda { telnet_with(socket).waitfor(/\$ \z/n) }.should raise_error(Net::ReadTimeout)
  end

  it "matches the String option literally" do
    socket = FakeTelnetSocket.new("cost: $5 (ok)")
    telnet_with(socket).waitfor("String" => "$5 (ok)").should == "cost: $5 (ok)"
  end

  it "raises ArgumentError when the hash has no Match, Prompt or String" do
    socket = FakeTelnetSocket.new("x$ ")
    lambda { telnet_with(socket).waitfor("Timeout" => 1) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError when passed nil" do
    socket = FakeTelnetSocket.new("x$ ")
    lambda { telnet_with(socket).waitfor(nil) }.should raise_error(ArgumentError)
  end

  it "yields the data as it is received" do
    socket = FakeTelnetSocket.new("ab", "c$ ")
    yielded = []
    telnet_with(socket).waitfor(/\$ \z/n) { |c| yielded << c }
    yielded.should == ["ab", "c$ "]
  end
end
