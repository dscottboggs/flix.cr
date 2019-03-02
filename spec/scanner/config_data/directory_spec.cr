require "../../spec_helper"

describe Flix::Scanner::MediaDirectory::ConfigData do
  it "sets the basic properties" do
    subject = Flix::Scanner::MediaDirectory.from_file_path?(TEST_MEDIA_DIR).as Flix::Scanner::MediaDirectory
    cd = subject.config_data
    subject.name.should eq cd.title
    subject.children_videos.map(&.hash).should eq cd.content.keys
    subject.children_videos.map(&.name).should eq cd.content.values.map &.title
  end
  it "matches the stored snapshot" do
    subject = Flix::Scanner::MediaDirectory.from_file_path?(TEST_MEDIA_DIR).as Flix::Scanner::MediaDirectory
    subject.config_data.to_yaml.should eq <<-YAML
    ---
    title: Media
    content:
      #{Flix::Scanner.hash VIDEO_TWO_PATH}:
        title: Test Video - 2
      #{Flix::Scanner.hash VIDEO_ONE_PATH}:
        thumbnail: #{IMAGE_ONE_PATH}
        title: Test Video
        subtitles:
          es: /home/scott/Documents/code/flix/test_data/media/TestVideo.es.srt
          en: /home/scott/Documents/code/flix/test_data/media/TestVideo.en.ssa

    YAML
  end
  it "reads in yaml" do
    subject = Flix::Scanner::MediaDirectory::ConfigData.from_yaml <<-YAML
    ---
    title: Media
    content:
      #{Flix::Scanner.hash VIDEO_TWO_PATH}:
        title: Test Video - 2
      #{Flix::Scanner.hash VIDEO_ONE_PATH}:
        title: Test Video

    YAML
  end
end
