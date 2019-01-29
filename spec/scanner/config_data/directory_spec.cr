require "../../spec_helper"

describe Flix::Scanner::MediaDirectory::ConfigData do
  it "sets the basic properties" do
    subject = Flix::Scanner::MediaDirectory.from_file_path?(TEST_MEDIA_DIR).as Flix::Scanner::MediaDirectory
    cd = subject.config_data
    subject.name.should eq cd.title
    subject.children.keys.should eq cd.content.keys
    subject.children.values.map(&.name).should eq cd.content.values.map &.title
  end
end
