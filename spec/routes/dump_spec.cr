require "../routes_spec"

FilePathHashes = {TestVideo: Flix::Scanner.hash(VIDEO_ONE_PATH), TestVideo2: Flix::Scanner.hash(VIDEO_TWO_PATH)}
EXPECTED_DUMP  = [
  {
    "title"                     => "media",
    FilePathHashes[:TestVideo2] => "Test Video - 2",
    FilePathHashes[:TestVideo]  => "Test Video",
  },
]
describe "/dmp" do
  it "dumps a given state" do
    get "/dmp"
    Array(Hash(String, String)).from_json(response.body).should eq EXPECTED_DUMP
  end
end
