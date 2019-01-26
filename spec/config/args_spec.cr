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
      test_config.sign_in_endpoint.should eq Flix::Configuration::Defaults.sign_in_endpoint
      # test_config.allow_unauthorized.should be_false, except that we're
      # disabling auth for testing purposes, so actually
      test_config.allow_unauthorized.should be_true
    end
  end
  context "with options" do
    {% for ctx, path in {"absolute path" => "#{__DIR__}/test_data", "relative path" => "test_data"} %}
    context "using a {{ctx.id}}" do
      it "parses the args correctly" do
        test_config = Flix::Configuration.from_args(\%w<
          --dir {{path.id}}/media
          --config {{path.id}}/config
          --port 1234
          --webroot /tmp
          --processes 2
          --sign-in-endpoint /login
        >)
        # test_config.dirs.should contain Flix::Scanner::VideoFile.new "{{path.id}}/media/TestVideo.mp4"
        test_config.config_location.should eq "{{path.id}}/config"
        test_config.port.should eq 1234
        test_config.webroot.should eq "/tmp"
        test_config.processes.should eq 2
        test_config.sign_in_endpoint.should eq "/login"
      end
    end
    {% end %}
    it "should raise an exception if --cert-file is specified but --key-file isn't" do
      expect_raises Flix::Configuration::CertArgsError do
        Flix::Configuration.from_args ["--cert-file"]
      end
    end
    it "should raise an exception if --key-file is specified but --cert-file isn't" do
      expect_raises Flix::Configuration::CertArgsError do
        Flix::Configuration.from_args ["--key-file"]
      end
    end
    context "when port number is 0" do
      it "should raise a descriptive exception" do
        expect_raises Exception, message: "port cannot be 0" do
          Flix::Configuration.from_args ["--port", "0"]
        end
      end
    end
    context "when port number is out of the right range" do
      it "should raise a descriptive exception" do
        expect_raises ArgumentError do
          Flix::Configuration.from_args ["--port", "65536"]
        end
      end
    end
  end
end
