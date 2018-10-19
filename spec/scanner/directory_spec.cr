describe Scanner::MediaDirectory do
  describe ".from_file_path" do
    it "works" do
      test_obj = Scanner::MediaDirectory.from_file_path? TEST_MEDIA_DIR
      test_obj.should_not be_nil
      unless (t_obj = test_obj).nil?
        t_obj.path.should eq TEST_MEDIA_DIR
        t_obj.name.should eq "media"
        t_obj.children.is_a?(Hash(String, Scanner::FileMetadata)).should be_true
        t_obj.children.should_not be_nil
        unless (children = t_obj.children).nil?
          children.each do |hash, f_obj|
            hash.is_a?(String).should be_true
            f_obj.is_a?(Scanner::VideoFile).should be_true
            {"Test Video", "Test Video - 2"}.should contain f_obj.name
          end
        end
      end
    end
  end
end
