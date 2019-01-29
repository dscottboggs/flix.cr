require "../../spec_helper"

describe Flix::Scanner::VideoFile::ConfigData do
  it "sets the right values" do
    subject = Flix::Scanner::VideoFile.from_file_path?(
      TEST_FILES[:video_one].path, TEST_FILES[:video_one].info).not_nil!
    subject.thumbnail = Flix::Scanner::PhotoFile.from_file_path?(
      TEST_FILES[:image_one].path, TEST_FILES[:image_one].info
    ).as Flix::Scanner::PhotoFile
    cd = subject.config_data
    subject.name.should eq cd.title
    subject.thumbnail.not_nil!.path.should eq cd.thumbnail
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
