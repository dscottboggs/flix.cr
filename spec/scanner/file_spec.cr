require "../spec_helper"

describe "mime_type" do
  it "reports its mime type" do
    context (file = TEST_FILES[:video_one]) do
      Flix::Scanner::MimeType.of(file.path).should eq Flix::Scanner::MimeType::MP4
    end
    context (file = TEST_FILES[:video_two]) do
      Flix::Scanner::MimeType.of(file.path).should eq Flix::Scanner::MimeType::MP4
    end
    context (file = TEST_FILES[:image_one]) do
      Flix::Scanner::MimeType.of(file.path).should eq Flix::Scanner::MimeType::JPEG
    end
  end
end
