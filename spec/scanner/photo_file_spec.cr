require "../spec_helper"
describe Flix::Scanner::PhotoFile do
  it "initializes properly" do
    test_obj = Flix::Scanner::PhotoFile.new "/test/path.to.file.jpg"
    test_obj.path.should eq "/test/path.to.file.jpg"
    test_obj.name.should eq "path to file"
  end
  describe ".from_file_path" do
    it "works" do
      test_obj = Flix::Scanner::PhotoFile.from_file_path? TEST_FILES[:image_one].path
      test_obj.should be_nil
    end
  end
end
