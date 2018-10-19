describe Flix::Scanner::VideoFile do
  describe "#initialize" do
    it "works" do
      test_obj = Flix::Scanner::VideoFile.new "/test/path.to.file.mp4"
      test_obj.path.should eq "/test/path.to.file.mp4"
      test_obj.name.should eq "path to file"
    end
  end
  describe ".from_file_path" do
    it "works" do
      test_obj = Flix::Scanner::VideoFile.from_file_path? TEST_FILES[:video_one].path
      test_obj.should_not be_nil
      unless (t_obj = test_obj).nil?
        t_obj.path.should eq TEST_FILES[:video_one].path
        t_obj.name.should eq "Test Video"
      end
    end
  end
end
