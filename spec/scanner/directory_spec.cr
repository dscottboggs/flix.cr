describe Flix::Scanner::MediaDirectory do
  test_obj = Flix::Scanner::MediaDirectory.from_file_path? TEST_MEDIA_DIR
  describe ".from_file_path" do
    it "works" do
      test_obj.should_not be_nil
      unless (t_obj = test_obj).nil?
        t_obj.path.should eq TEST_MEDIA_DIR
        t_obj.name.should eq "media"
        t_obj.children.is_a?(Hash(String, Flix::Scanner::FileMetadata)).should be_true
        t_obj.children.should_not be_nil
        unless (children = t_obj.children).nil?
          children.each do |hash, f_obj|
            hash.is_a?(String).should be_true
            f_obj.is_a?(Flix::Scanner::VideoFile).should be_true
            {"Test Video", "Test Video - 2"}.should contain f_obj.name
          end
        end
      end
    end
  end
  describe "#to_json" do
    it "outputs the right JSON" do
      json = JSON.parse test_obj.to_json
      json["title"].should eq "media"
      test_obj.each_child do |hash, f_obj|
        json[hash].should eq f_obj.name
      end
    end
  end
end
