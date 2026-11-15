# encoding: binary
require_relative '../../lib/net/telnet'

class FakeTelnetSocket
  attr_reader :written

  def initialize(*chunks, max_write: nil)
    @chunks = []
    @triggers = []
    @max_write = max_write
    @written = "".b
    feed(*chunks)
  end

  def feed(*chunks)
    @chunks.concat(chunks.map { |c| c == :eof ? c : c.b })
  end

  def on_write(text, *chunks)
    @triggers << [text.b, chunks]
  end

  def clear
    @written = "".b
  end

  def sync=(value)
  end

  def binmode
    self
  end

  def kind_of?(klass)
    klass == IO || super
  end

  def wait_readable(timeout = nil)
    @chunks.empty? ? nil : self
  end

  def readpartial(maxlen)
    chunk = @chunks.shift
    raise EOFError if chunk.nil? || chunk == :eof
    chunk
  end

  def wait_writable(timeout = nil)
    self
  end

  def syswrite(string)
    data = string.b
    data = data.byteslice(0, @max_write) if @max_write
    @written << data
    @triggers.reject! do |text, chunks|
      feed(*chunks) if @written.end_with?(text)
    end
    data.bytesize
  end
end

def telnet_with(socket, options = {})
  Net::Telnet.new({"Proxy" => socket}.merge(options))
end
