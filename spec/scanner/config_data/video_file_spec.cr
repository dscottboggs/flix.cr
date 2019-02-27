require "../../spec_helper"

describe Flix::Scanner::VideoFile::ConfigData do
  it "sets the right values" do
    subject = Flix::Scanner::VideoFile.from_file_path?(
      TEST_FILES[:video_one].path,
      TEST_FILES[:video_one].info).as Flix::Scanner::VideoFile
    subject.thumbnail = Flix::Scanner::PhotoFile.from_file_path?(
      TEST_FILES[:image_one].path,
      TEST_FILES[:image_one].info ).as Flix::Scanner::PhotoFile
    subject.subtitles[Languages::English] = Flix::Scanner::SubtitleFile.from_file_path?(
      TEST_FILES[:english_subtitles].path,
      TEST_FILES[:english_subtitles].info ).as Flix::Scanner::SubtitleFile
    cd = subject.config_data
    subject.name.should eq cd.title
    subject.thumbnail.not_nil!.path.should eq cd.thumbnail
    subject.subtitles.not_nil![Languages::English].should be_a Flix::Scanner::SubtitleFile
  end
  it "properly merges mutated values" do
    subject = Flix::Scanner::VideoFile
      .from_file_path?(TEST_FILES[:video_one].path, TEST_FILES[:video_one].info)
      .as Flix::Scanner::VideoFile
    cd = subject.config_data
    cd.thumbnail = TEST_FILES[:image_one].path
    cd.title = "A different title"
    subject.merge! cd
    subject.name.should eq "A different title"
  end
end
