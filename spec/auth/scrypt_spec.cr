describe Scrypt::Password do
  it "serializes to JSON" do
    data = IO::Memory.new
    builder = JSON::Builder.new io: data
    builder.document do
      Scrypt::Password.create("dummy password").to_json(builder)
    end
    data.rewind
    Scrypt::Password.new(JSON::PullParser.new(data)).should eq "dummy password"
  end
end
