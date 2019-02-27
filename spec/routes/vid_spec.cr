require "../routes_spec"

describe "/vid" do
  it "streams a video found in the /dmp results" do
    get "/dmp"
    response.status_code.should eq 200
    id = Array(Hash(String, String))
      .from_json(response.body)
      .first
      .reject("title", "thumbnail")
      .keys
      .first
    get "/vid/#{id}"
    response.status_code.should eq 200
    response.headers["Content-Type"]?.should eq "application/octet-stream"
  end
end
