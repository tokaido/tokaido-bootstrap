describe "Tokaido::Bootstrap::Protocol" do
  before do
    @protocol = Tokaido::Bootstrap::Protocol.new("tokaido")
    @dirname = File.expand_path("..", __FILE__)
  end

  it "decodes a stop request" do
    request = @protocol.decode("STOP")

    request.should_not be_error
    request.type.should == "STOP"
  end

  it "decodes an add request" do
    request = @protocol.decode(%{ADD "#{@dirname}" "foo.tokaido" 9292})

    request.should_not be_error
    request.type.should == "ADD"
    request.directory.should == @dirname
    request.host.should == "foo.tokaido"
    request.port.should == 9292
  end

  it "returns an error if the format is invalid" do
    request = @protocol.decode(%{AD /Code/foo foo.tokaido 9292})

    request.should be_error
    request.reason.should == "INVALID"
  end

  it "returns an error if the domain is incorrect" do
    request = @protocol.decode(%{ADD "#{@dirname}" "foo.dev" 9292})

    request.should be_error
    request.reason.should == %{ERR "foo.dev" invalid-host}
  end

  it "returns an error if the directory does not exist" do
    request = @protocol.decode(%{ADD "#{@dirname}/noexist" "foo.tokaido" 9292})

    request.should be_error
    request.reason.should == %{ERR "foo.tokaido" dir-not-found}
  end
end
