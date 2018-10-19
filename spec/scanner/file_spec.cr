require "../spec_helper"

describe "mime_type" do
  it "reports its mime type" do
    context (file = TEST_FILES[:video_one]) do
      Flix::Scanner.mime_type(file.path).should eq :mp4
    end
    context (file = TEST_FILES[:video_two]) do
      Flix::Scanner.mime_type(file.path).should eq :mp4
    end
    context (file = TEST_FILES[:image_one]) do
      Flix::Scanner.mime_type(file.path).should eq :jpeg
    end
  end
end
