require "../spec_helper"
describe Flix::Scanner::PhotoFile do
  it "initializes properly" do
    test_obj = Flix::Scanner::PhotoFile.new "/test/path.to.file.jpg"
    test_obj.path.should eq "/test/path.to.file.jpg"
    test_obj.name.should eq "path to file"
  end
  describe ".from_file_path" do
    it "works" do
      if test_obj = Flix::Scanner::PhotoFile.from_file_path? TEST_FILES[:image_one].path
        test_obj.mime_type!.is_a_photo?.should be_true
        test_obj.path.should eq TEST_FILES[:image_one].path
      else
        fail "Flix::Scanner::PhotoFile.from_file_path? TEST_FILES[:image_one].path was nil"
      end
    end
  end
end
