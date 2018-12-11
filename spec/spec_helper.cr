# ENV["FLIX_DEBUG"] = "yes"

require "spec"
require "http"
require "../src/flix"

URLS = {
  video_one: "https://s3.amazonaws.com/x265.org/video/Tractor_500kbps_x264.mp4",
  video_two: "https://s3.amazonaws.com/x265.org/video/BigBuckBunny_2000hevc.mp4",
}

TEST_DATA_DIR   = File.join Dir.current, "test_data"
TEST_MEDIA_DIR  = File.join TEST_DATA_DIR, "media"
TEST_CONFIG_DIR = File.join TEST_DATA_DIR, "config"

VIDEO_ONE_PATH = File.join(TEST_MEDIA_DIR, "TestVideo.mp4")
VIDEO_TWO_PATH = File.join(TEST_MEDIA_DIR, "Test.Video.-.2.mp4")
IMAGE_ONE_PATH = File.join(TEST_MEDIA_DIR, "TestVideo.jpg")

TEST_FILES = {
  video_one: File.open(VIDEO_ONE_PATH),
  video_two: File.open(VIDEO_TWO_PATH),
  image_one: File.open(IMAGE_ONE_PATH),
}

Flix.config = Flix::Configuration.new(
  config_location: TEST_CONFIG_DIR,
  dirs: [TEST_MEDIA_DIR],
  port: 21222_u16,
)
