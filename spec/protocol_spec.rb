describe "Tokaido::Bootstrap::Protocol" do
  before do
    @protocol = Tokaido::Bootstrap::Protocol.new("tokaido")
    @dirname = File.expand_path("..", __FILE__)
  end

  it "decodes a stop request" do
    request = @protocol.decode("STOP")

    expect(request).not_to be_error
    expect(request.type).to eql("STOP")
  end

  it "decodes a remove request" do
    request = @protocol.decode(%{REMOVE "#{@dirname}" "foo.tokaido"})

    expect(request).not_to be_error
    expect(request.type).to eql("REMOVE")
  end

  it "decodes an add request" do
    request = @protocol.decode(%{ADD "#{@dirname}" "foo.tokaido" 9292})

    expect(request).to_not be_error
    expect(request.type).to eql("ADD")
    expect(request.directory).to eql(@dirname)
    expect(request.host).to eql("foo.tokaido")
    expect(request.port).to eql("9292")
  end

  it "returns an error if the format is invalid" do
    request = @protocol.decode(%{AD /Code/foo foo.tokaido 9292})

    expect(request).to be_error
    expect(request.reason).to eql("INVALID")
  end

  it "returns an error if the domain is incorrect" do
    request = @protocol.decode(%{ADD "#{@dirname}" "foo.dev" 9292})

    expect(request).to be_error
    expect(request.reason).to eql(%{ERR "foo.dev" invalid-host})
  end

  it "allows the port to be optional" do
    request = @protocol.decode(%{ADD "#{@dirname}" "foo.tokaido"})

    expect(request).not_to be_error
    expect(request.port).to be_nil
  end

  it "returns an error if the directory does not exist" do
    request = @protocol.decode(%{ADD "#{@dirname}/noexist" "foo.tokaido" 9292})

    expect(request).to be_error
    expect(request.reason).to eql(%{ERR "foo.tokaido" dir-not-found})
  end
end
