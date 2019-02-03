require "../routes_spec"

FilePathHashes = {TestVideo: Flix::Scanner.hash(VIDEO_ONE_PATH), TestVideo2: Flix::Scanner.hash(VIDEO_TWO_PATH)}
EXPECTED_DUMP  = [
  {
    "title"                     => "Media",
    FilePathHashes[:TestVideo2] => "Test Video - 2",
    FilePathHashes[:TestVideo]  => "Test Video",
  },
]
describe "/dmp" do
  it "dumps a given state" do
    get "/dmp"
    response.status_code.should eq 200
    Array(Hash(String, String)).from_json(response.body).should eq EXPECTED_DUMP
  end
end
