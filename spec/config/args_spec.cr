require "../spec_helper"

describe "Flix::Configuration.from_args" do
  context "defaults" do
    it "has the correct options" do
      test_config = Flix::Configuration.from_args([] of String)
      # test_config.dirs.should eq Flix::Configuration::Defaults.media_dirs
      # media dir gets scanned, must have files in it, this is a problem
      test_config.webroot.should eq Flix::Configuration::Defaults.webroot
      test_config.port.should eq Flix::Configuration::Defaults.port
      test_config.config_location.should eq Flix::Configuration::Defaults.config_location
      test_config.processes.should eq 1
    end
  end
  context "with options" do
    {% for ctx, path in {"absolute path" => "#{__DIR__}/test_data", "relative path" => "test_data"} %}
    context "using a {{ctx.id}}" do
      it "parses the args correctly" do
        test_config = Flix::Configuration.from_args(\%w<--dir {{path.id}}/media --config {{path.id}}/config --port 1234 --webroot /tmp --processes 2>)
        # test_config.dirs.should contain Flix::Scanner::VideoFile.new "{{path.id}}/media/TestVideo.mp4"
        test_config.config_location.should eq "{{path.id}}/config"
        test_config.port.should eq 1234
        test_config.webroot.should eq "/tmp"
        test_config.processes.should eq 2
      end
    end
    {% end %}
  end
end
