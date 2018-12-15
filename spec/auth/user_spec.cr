describe Flix::Authentication::User do
  it "loads from the received jwt token type" do
    data = Hash(String, JSON::Any){"name" => JSON::Any.new("test_user")}
    result = Flix::Authentication::User.load(data)
    result.should be_a UserHash
    result["error"]?.should be_nil
    result["name"].should eq "test_user"
  end
  describe "#is_authenticated_by?" do
    it "validates the correct password" do
      Flix::Authentication::User.new("TEST USER").is_authenticated_by?(
        File.read(
          File.join(TEST_CONFIG_DIR, "unencrypted_test_user_password")
        )
      ).should be_true
    end
    it "responds with false for the incorrect password" do
      Flix::Authentication::User.new("TEST USER").is_authenticated_by?("some nonsense").should be_false
    end
    it "responds with false when the user does not exist" do
      Flix::Authentication::User.new("nonexistent user").is_authenticated_by?("anything").should be_false
      Flix::Authentication::User.new("nonexistent user").is_authenticated_by?("").should be_false
      # the next line causes a compile-time error when uncommented.
      # Flix::Authentication::User.new("nonexistent user").is_authenticated_by?(nil).should be_false
    end
  end
  describe "#exists?" do
    it "replies with true when the user does exist" do
      Flix::Authentication::User.new("TEST USER").exists?.should be_true
    end
    it "replies with false when the user does not exist" do
      Flix::Authentication::User.new("nonexistent user").exists?.should be_false
    end
  end
end
