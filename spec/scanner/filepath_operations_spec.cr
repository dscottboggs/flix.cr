require "../spec_helper"

struct TestEntry
  property original : String
  property expected : String
  property kind : String

  def initialize(@original, @expected, @kind); end

  def inspect
    "Test case that #{original} becomes #{expected}"
  end
end

include Flix::Scanner::FilepathOperations

{% for kind in ["pascal case", "underscore separated", "dot separated", "with spaces", "camel case"] %}
macro test_{{kind.id.gsub /\s/, "_"}}_filepath_to_title(original, expected)
  context (entry = TestEntry.new \{{original}}, \{{expected}}, {{kind}}) do
    it "handles format '#{entry.kind}' with example #{entry.original}" do
      get_title_from(entry.original).should eq entry.expected
    end
  end
end
{% end %}

describe Flix::Scanner::FilepathOperations do
  describe ".get_title_from" do
    test_pascal_case_filepath_to_title "TestString", "Test String"
    test_pascal_case_filepath_to_title "TestString.mp4", "Test String"
    test_pascal_case_filepath_to_title "TestString-TheTestening.webm", "Test String - The Testening"
    test_underscore_separated_filepath_to_title "Test_String.mp4", "Test String"
    test_dot_separated_filepath_to_title "Test.String.mp4", "Test String"
    test_dot_separated_filepath_to_title "Test.String.-.The.Testening.mp4", "Test String - The Testening"
    test_dot_separated_filepath_to_title "Title.For.Dot-Separated.Dir.With.Long.Final.Substring", "Title For Dot-Separated Dir With Long Final Substring"
    test_with_spaces_filepath_to_title "Test Filename with Spaces.mp4", "Test Filename with Spaces"
    test_camel_case_filepath_to_title "testString", "Test String"
  end

  describe ".language_code" do
    {% begin %}
      {%
        test_cases = {
          "/path/to/video.en.srt" => "en",
          "/path/to/video/jp"     => "jp",
          "/path/to/video/fr.ssa" => "fr",
        }
      %}
      {% for path, code in test_cases %}
        context {{path}} do
          it "finds the language code in the path" do
            language_code( found_in: {{path}}).should eq {{code}}
          end
        end
      {% end %}
    {% end %}
  end
  describe ".without_language_code" do
    it "strips a language code and extension from a filepath" do
      without_language_code("/path/to/video.en.ssa").should eq "/path/to/video"
    end
    it "also strips any arbitrary text off of the end of the filepath that ends with two \"extensions\" that are less than 5 characters" do
      without_language_code("arbitrary.file.name").should eq "arbitrary"
    end
  end

  describe ".without_extension" do
    it "strips an extension from a filepath" do
      without_extension(File.basename "/path/to/video.mkv").should eq "video"
    end
  end
end
