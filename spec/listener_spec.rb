require 'tokaido/bootstrap/manager'

describe "Tokaido::Bootstrap::Listener" do
  before do
    @dirname = File.expand_path("..", __FILE__)

    muxr = File.join(@dirname, "muxr.sock")
    firewall = File.join(@dirname, "firewall.sock")

    @manager = Tokaido::Bootstrap::Manager.new(muxr, firewall, @dirname)
    @server = double(:server)

    @listener = Tokaido::Bootstrap::Listener.new(@manager, @server)
  end

  it "adds a Tokaido app" do
    expect(@manager).to receive(:add_app)
    @listener.process_request(%{ADD "foo.tokaido" "#{@dirname}" 9292})
  end

  it "removes a Tokaido app" do
    expect(@manager).to receive(:remove_app)
    @listener.process_request(%{REMOVE "foo.tokaido"})
  end


end
