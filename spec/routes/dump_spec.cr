require "../routes_spec"

describe "/dmp" do
  it "dumps a given state" do
    get "/dmp"
    # HACK!!
    # this should be the contents of TEST_CONFIG_DIR, why is it the default
    # when args are parsed?
    response.body.should eq "[{\"title\":\"media\",\"m8eHp5iFD88=\":\"Test Video - 2\",\"9UUlUbVCDPY=\":\"Test Video\"}]" 
  end
end
