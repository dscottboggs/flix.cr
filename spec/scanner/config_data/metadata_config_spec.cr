require "../../spec_helper"

def reset_metadata_file
  Flix.config.metadata_file do |mf|
    if mf.is_a? IO::Memory
      mf.clear
    end
  end
end

describe Flix::MetadataConfig do
  it "matches the snapshot" do
    Flix::MetadataConfig.synchronize!
    Flix.config.metadata_file do |mf|
      mf.to_s.should eq <<-YAML
    ---
    folders:
      #{Flix::Scanner.hash TEST_MEDIA_DIR}:
        title: Media
        content:
          #{Flix::Scanner.hash TEST_FILES[:video_two].path}:
            title: Test Video - 2
          #{Flix::Scanner.hash TEST_FILES[:video_one].path}:
            thumbnail: #{TEST_FILES[:image_one].path}
            title: Test Video
            subtitles:
              es: /home/scott/Documents/code/flix/test_data/media/TestVideo.es.srt
              en: /home/scott/Documents/code/flix/test_data/media/TestVideo.en.ssa

    YAML
    end
  ensure
    reset_metadata_file
  end
  it "successfully accepts an update" do
    Flix::MetadataConfig.synchronize!

    old_state = IO::Memory.new Flix.config.metadata_file &.to_s
    modified = <<-YAML
    ---
    folders:
      #{Flix::Scanner.hash TEST_MEDIA_DIR}:
        title: Media
        content:
          #{Flix::Scanner.hash TEST_FILES[:video_two].path}:
            title: Test Video - 2
          #{Flix::Scanner.hash TEST_FILES[:video_one].path}:
            title: Updated title!
            thumbnail: #{File.join Dir.current, TEST_FILES[:image_one].path}

    YAML
    Flix.config.metadata_file do |mf|
      if mf.is_a? IO::Memory
        mf.clear
      else
        fail "got unexpectedly typed metadata_file: #{mf.class}"
      end
    end
    Flix.config.metadata_file { |mf| modified.to_s mf; mf.rewind }
    Flix::MetadataConfig.synchronize!
    Flix.config
      .dirs
      .first
      .find_video { |video| video.name === "Updated title!" }
      .should_not be_nil
    Flix.config.metadata_file do |mf|
      if mf.is_a? IO::Memory
        mf.clear
      else
        fail "got unexpectedly typed metadata_file: #{mf.class}"
      end
    end
    Flix.config.metadata_file do |mf|
      old_state.to_s mf
      mf.rewind
    end
    Flix::MetadataConfig.synchronize!
    Flix.config
      .dirs
      .first
      .find_video { |video| video.name === "Updated title!" }
      .should be_nil
  ensure
    reset_metadata_file
  end

  it "throws an exception when invalid YAML is encountered" do
    Flix::MetadataConfig.synchronize!
    # save the original state
    old_state = IO::Memory.new Flix.config.metadata_file &.to_s
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
    Flix.config.metadata_file do |mf|
      if mf.is_a? IO::Memory
        mf.clear
      else
        fail "got unexpectedly typed metadata_file: #{mf.class}"
      end
    end
    # so we can set the modified to the virtual config file
    Flix.config.metadata_file do |mf|
      modified.to_s io: mf
      mf.rewind
    end
    # here's what we're actually testing for
    expect_raises YAML::ParseException do
      Flix::MetadataConfig.synchronize!
    end
    # and make sure that the invalid state wasn't written
    Flix.config.metadata_file &.rewind.gets_to_end.should eq old_state.gets_to_end
  end
  it "ignores the error when invalid YAML is encountered at the beginning of the file" do
    Flix::MetadataConfig.synchronize!
    # save the original state
    old_state = IO::Memory.new Flix.config.metadata_file &.to_s
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
    Flix.config.metadata_file do |mf|
      if mf.is_a? IO::Memory
        mf.clear
      else
        fail "got unexpectedly typed metadata_file: #{mf.class}"
      end
    end
    # so we can set the modified to the virtual config file
    Flix.config.metadata_file do |mf|
      modified.to_s io: mf
      mf.rewind
    end
    # here's what we're actually testing for -- this shouldn't raise.
    Flix::MetadataConfig.synchronize!
    # and make sure that the invalid state wasn't written
    Flix.config.metadata_file &.rewind.gets_to_end.should eq old_state.gets_to_end
  end
end
