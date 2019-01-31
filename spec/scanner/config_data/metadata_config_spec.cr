require "../../spec_helper"

describe Flix::MetadataConfig do
  it "matches the snapshot" do
    Flix::MetadataConfig.synchronize!
    Flix.config.metadata_file.to_s.should eq <<-YAML
    ---
    folders:
      E9zk2zyWEDo:
        title: Media
        content:
          m8eHp5iFD88:
            title: Test Video - 2
          9UUlUbVCDPY:
            title: Test Video
            thumbnail: /home/scott/Documents/code/flix/test_data/media/TestVideo.jpg

    YAML
  end
  it "successfully accepts an update" do
    old_state = Flix.config.dirs.clone
    modified = <<-YAML
    folders:
      E9zk2zyWEDo:
        title: Media
        content:
          m8eHp5iFD88:
            title: Test Video - 2
          9UUlUbVCDPY:
            title: Updated title!
            thumbnail: /home/scott/Documents/code/flix/test_data/media/TestVideo.jpg

    YAML
    modified.to_s Flix.config.metadata_file.rewind
    Flix.config.metadata_file.rewind
    Flix::MetadataConfig.synchronize!
    Flix.config
      .dirs
      .first
      .children
      .find { |_, child| child.name === "Updated title!" }
      .should_not be_nil
    Flix.config.dirs = old_state
    # reset state for other tests
    if (mf = Flix.config.metadata_file).is_a? IO::Memory
      mf.clear
    end
  end
end
