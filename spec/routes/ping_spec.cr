require "../routes_spec"

describe "/ping" do
  it "responds" do
    get "/ping"
    response.body.should eq "pong"
  end
end
