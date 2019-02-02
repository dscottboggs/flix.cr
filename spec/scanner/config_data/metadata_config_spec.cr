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

  it "throws an exception when invalid YAML is encountered" do
    Flix::MetadataConfig.synchronize!
    # save the original state
    old_state = IO::Memory.new Flix.config.metadata_file.to_s
    # set up some invalid YAML
    modified = <<-YAML
    ---
    folders:
      E9zk2zyWEDo: invalid yaml here: }
        title: Media
        content:
          m8eHp5iFD88:
            title: Test Video - 2
          9UUlUbVCDPY:
            title: Updated title!
            thumbnail: /home/scott/Documents/code/flix/test_data/media/TestVideo.jpg

    YAML
    # clear out the current state
    if (mf = Flix.config.metadata_file).is_a? IO::Memory
      mf.clear
    else
      fail "got unexpectedly typed metadata_file: #{Flix.config.metadata_file.class}"
    end
    # so we can set the modified to the virtual config file
    modified.to_s io: Flix.config.metadata_file
    Flix.config.metadata_file.rewind
    # here's what we're actually testing for
    expect_raises YAML::ParseException do
      Flix::MetadataConfig.synchronize!
    end
    # and make sure that the invalid state wasn't written
    Flix.config.metadata_file.rewind.gets_to_end.should eq old_state.gets_to_end
  end
  it "ignores the error when invalid YAML is encountered at the beginning of the file" do
    Flix::MetadataConfig.synchronize!
    # save the original state
    old_state = IO::Memory.new Flix.config.metadata_file.to_s
    # set up some invalid YAML
    modified = <<-YAML
    } <<-- bad yaml
    folders:
      E9zk2zyWEDo: invalid yaml here: }
        title: Media
        content:
          m8eHp5iFD88:
            title: Test Video - 2
          9UUlUbVCDPY:
            title: Updated title!
            thumbnail: /home/scott/Documents/code/flix/test_data/media/TestVideo.jpg

    YAML
    # clear out the current state
    if (mf = Flix.config.metadata_file).is_a? IO::Memory
      mf.clear
    else
      fail "got unexpectedly typed metadata_file: #{Flix.config.metadata_file.class}"
    end
    # so we can set the modified to the virtual config file
    modified.to_s io: Flix.config.metadata_file
    Flix.config.metadata_file.rewind
    # here's what we're actually testing for -- this shouldn't raise.
    Flix::MetadataConfig.synchronize!
    # and make sure that the invalid state wasn't written
    Flix.config.metadata_file.rewind.gets_to_end.should eq old_state.gets_to_end
  end
end
