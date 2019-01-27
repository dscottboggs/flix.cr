require "../spec_helper"
describe Flix::Scanner::MediaDirectory do
  test_obj = Flix::Scanner::FileMetadata.from_file_path? TEST_MEDIA_DIR
  describe ".from_file_path" do
    it "works" do
      test_obj.should_not be_nil
      unless (t = test_obj).nil?
        t.is_dir?.should be_true
        if t.is_dir?
          t_obj = t.as(Flix::Scanner::MediaDirectory)
          t_obj.path.should eq TEST_MEDIA_DIR
          t_obj.name.should eq "Media"
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
  end
  describe "#to_json" do
    it "outputs the right JSON" do
      test_obj.should_not be_nil
      unless (t = test_obj).nil?
        t.is_dir?.should be_true
        if t.is_dir?
          t_obj = t.as(Flix::Scanner::MediaDirectory)
          json = JSON.parse t_obj.to_json
          json["title"].should eq "Media"
          t_obj.each_child do |hash, f_obj|
            json[hash].should eq f_obj.name
          end
        end
      end
    end
  end
end
