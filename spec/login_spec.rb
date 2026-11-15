# encoding: binary
require_relative 'fixtures/fake_socket'

describe "Net::Telnet#cmd with default options" do
  it "sends the string with CR LF and returns the data up to the prompt" do
    socket = FakeTelnetSocket.new
    socket.on_write("ls\r\n", "ls\r\nfile\r\n$ ")
    telnet_with(socket).cmd("ls").should == "ls\nfile\n$ "
    socket.written.should == "ls\r\n"
  end

  it "waits for the Match option" do
    socket = FakeTelnetSocket.new
    socket.on_write("go\r\n", "ready> ")
    telnet_with(socket).cmd("String" => "go", "Match" => /> \z/n).should == "ready> "
  end
end

describe "Net::Telnet#login with default options" do
  it "sends the name and password at the matching prompts" do
    socket = FakeTelnetSocket.new("login: ")
    socket.on_write("user\r\n", "user\r\nPassword: ")
    socket.on_write("secret\r\n", "\r\nWelcome\r\n$ ")
    telnet_with(socket).login("user", "secret").should ==
      "login: user\nPassword: \nWelcome\n$ "
    socket.written.should == "user\r\nsecret\r\n"
  end

  it "answers negotiation sent before the login prompt" do
    socket = FakeTelnetSocket.new("\xff\xfd\x18\xff\xfb\x01login: ")
    socket.on_write("user\r\n", "$ ")
    telnet_with(socket).login("user").should == "login: $ "
    socket.written.should == "\xff\xfc\x18\xff\xfd\x01user\r\n"
  end
end
