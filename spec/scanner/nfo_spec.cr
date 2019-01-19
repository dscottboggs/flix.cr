require "../spec_helper"
describe Flix::Scanner::NFO do
  describe "Flix::Scanner::FileMetadata#nfo" do
    context TEST_FILES[:video_one].path do
      it "has the expected values" do
        if video = Flix::Scanner::FileMetadata.all_videos["9UUlUbVCDPY"]?
          nfo = video.nfo
          nfo.file_name.should eq "TestVideo.mp4"
          nfo.mime_type.should eq "video/mp4"
          nfo.parent_dir.should eq "E9zk2zyWEDo"
        else
          fail "didn't find video with ID s4cTVQzqU0A in #{Flix.config.dirs.to_json}"
        end
      end
    end
    context TEST_MEDIA_DIR do
      it "has the expected values" do
        if dir = Flix.config.dirs.first
          nfo = dir.nfo
          nfo.file_name.should eq "media"
          nfo.mime_type.should eq "inode/directory"
          nfo.parent_dir.should eq ""
        else
          fail "didn't find video with ID s4cTVQzqU0A in #{Flix.config.dirs.to_json}"
        end
      end
    end
  end
end
