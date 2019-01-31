require "../../spec_helper"

def reset_metadata_file
  if (mf = Flix.config.metadata_file).is_a? IO::Memory
    mf.clear
  end
end

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

  ensure
    reset_metadata_file
  end
  it "successfully accepts an update" do
    Flix::MetadataConfig.synchronize!
    old_state = IO::Memory.new Flix.config.metadata_file.to_s
    modified = <<-YAML
    ---
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
    if (mf = Flix.config.metadata_file).is_a? IO::Memory
      mf.clear
    else
      fail "got unexpectedly typed metadata_file: #{Flix.config.metadata_file.class}"
    end
    modified.to_s Flix.config.metadata_file
    Flix.config.metadata_file.rewind
    Flix::MetadataConfig.synchronize!
    Flix.config
      .dirs
      .first
      .children
      .find { |_, child| child.name === "Updated title!" }
      .should_not be_nil
    if (mf = Flix.config.metadata_file).is_a? IO::Memory
      mf.clear
    else
      fail "got unexpectedly typed metadata_file: #{Flix.config.metadata_file.class}"
    end
    old_state.to_s Flix.config.metadata_file.rewind
    Flix.config.metadata_file.rewind
    Flix::MetadataConfig.synchronize!
    Flix.config
      .dirs
      .first
      .children
      .find { |_, child| child.name === "Updated title!" }
      .should be_nil
  ensure
    reset_metadata_file
  end
end
