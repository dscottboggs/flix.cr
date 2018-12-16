require "../routes_spec"

describe "/vid" do
  context "/m8eHp5iFD88=" do
    it "works" do
	  get "/vid/m8eHp5iFD88="
	  response.status_code.should eq 200
	  it "responds with the expected headers" do
		response.headers["Content-Type"]?.should eq "application/octet-stream"
	  end
    end
  end
end
