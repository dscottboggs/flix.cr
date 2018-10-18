require "spec"
require "tempfile"
require "http"
require "../src/flix"

URLS = {
  video_one: "https://s3.amazonaws.com/x265.org/video/Tractor_500kbps_x264.mp4",
  video_two: "https://s3.amazonaws.com/x265.org/video/BigBuckBunny_2000hevc.mp4",
}

TEST_DATA_DIR = File.join Dir.current, "test_data"
TEST_MEDIA_DIR = File.join TEST_DATA_DIR, "media"

TEST_FILES = {
  video_one: File.open(File.join TEST_MEDIA_DIR, "TestVideo.mp4"),
  video_two: File.open(File.join TEST_MEDIA_DIR, "Test.Video.-.2.mp4"),
  image_one: File.open(File.join TEST_MEDIA_DIR, "TestVideo.jpg"),
}
