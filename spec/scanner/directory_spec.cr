require "../spec_helper"
describe Flix::Scanner::MediaDirectory do
  test_obj = Flix::Scanner::FileMetadata.from_file_path?(TEST_MEDIA_DIR).as Flix::Scanner::MediaDirectory
  describe ".from_file_path" do
    it "works" do
      test_obj.should_not be_nil
      unless (t = test_obj).nil?
        t.is_dir?.should be_true
        if t.is_dir?
          t_obj = t.as Flix::Scanner::MediaDirectory
          t_obj.path.should eq TEST_MEDIA_DIR
          t_obj.name.should eq "Media"
          t_obj.children_videos.should be_a Array(Flix::Scanner::VideoFile)
          t_obj.children_directories.should be_a Array(Flix::Scanner::MediaDirectory)
          t_obj.each_video do |id, video|
            (id.is_a? String).should be_true
            video.is_a?(Flix::Scanner::VideoFile).should be_true
            {"Test Video", "Test Video - 2"}.should contain video.name
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
          t_obj = t.as Flix::Scanner::MediaDirectory
          json = JSON.parse t_obj.to_json
          json["title"].should eq "Media"
          t_obj.each_video do |hash, f_obj|
            json[hash].should eq f_obj.name
          end
        end
      end
    end
  end
  describe "#[](*, subtitle)" do
    it "finds a subtitle file" do
      test_subs = test_obj[subtitle: Flix::Scanner.hash SUBTITLE_SSA_PATH]
      test_subs.mime_type.try(&.is_a_subtitle?).should be_true
      test_subs.mime_type.try(&.is_substation?).should be_true
    end
  end
end
