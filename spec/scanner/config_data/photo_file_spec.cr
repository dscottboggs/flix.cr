require "../../spec_helper"

describe Flix::Scanner::PhotoFile::ConfigData do
  it "sets the expected attributes" do
    subject = Flix::Scanner::PhotoFile.from_file_path?(TEST_FILES[:image_one].path, TEST_FILES[:image_one].info).not_nil!
    cd = subject.config_data
    subject.name.should eq cd.title
    cd.thumbnail.should be_nil
  end
end
