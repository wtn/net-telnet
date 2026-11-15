# encoding: binary
require_relative 'fixtures/fake_socket'
require 'tmpdir'

describe "Net::Telnet.new with the Dump_log option" do
  it "creates the dump log readable only by its owner" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "dump.log")
      telnet_with(FakeTelnetSocket.new, "Dump_log" => path)
      (File.stat(path).mode & 0777).should == 0600
    end
  end
end
