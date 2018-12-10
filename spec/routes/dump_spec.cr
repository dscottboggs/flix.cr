require "../routes_spec"

describe "/dmp" do
  it "dumps a given state" do
    get "/dmp"
    # HACK!!
    # this should be the contents of TEST_CONFIG_DIR, why is it the default
    # when args are parsed?
    response.body.should eq <<-JSON
    [{"title":"Public","hciKo7Wx53Q=":{"title":"Looney Toons","uAvMpvAyJYM=":"Bugs Bunny - Wackiki Wabbit","s4cTVQzqU0A=":"Bugs Bunny - Fresh Hare","pRqiIcHYYTo=":"The Wabbit Who Came To Supper","qKe9qMporz4=":"Daffy Duck and the Dinosour","7_96xJtRHok=":"Bugs Bunny - The Wacky Wabbit"},"xXJkLIJ0LGw=":{"title":"Three Stooges","thumbnail":"aNxkgXaf0i8=","OIhfEZK_9TE=":"Disorder In The Court","kHylgsr4fLY=":"Malice In The Palace","99jwtFtZKbs=":"Sing A Song Of Six Pants","hug_BgZ3v4s=":"Brideless Groom"},"JbZ70dU6UGw=":"Peru 8k","OFRq21azPK4=":"Gulliver's Travels","CYi9n6akCcc=":"A Trip To The Moon","BbzHK9uwM-A=":"Superman"}]
    JSON
  end
end
