require "../spec_helper"

struct TestEntry
  property original : String
  property expected : String
  property kind : String
  def initialize(@original, @expected, @kind);end
end

describe Flix::Scanner::FileMetadata do
  describe ".get_title_from" do
    test_values = [
      TestEntry.new("TestString", "Test String", "pascal case"),
      TestEntry.new("TestString.mp4", "Test String", "pascal case"),
      TestEntry.new("TestString-TheTestening.webm", "Test String - The Testening", "pascal case"),
      TestEntry.new("Test_String.mp4", "Test String", "underscore separated"),
      TestEntry.new("Test.String.mp4", "Test String", "dot separated"),
      TestEntry.new("Test.String.-.The.Testening.mp4", "Test String - The Testening", "dot separated"),
      TestEntry.new("Title.For.Dot-Separated.Dir.With.Long.Final.Substring", "Title For Dot-Separated Dir With Long Final Substring", "dot-separated"),
      TestEntry.new("Test Filename with Spaces.mp4", "Test Filename with Spaces", "with spaces"),
      TestEntry.new("testString", "Test String", "camel case")
    ]
    test_values.each do |entry|
      it "handles format '#{entry.kind}' (example #{entry.original})" do
        Flix::Scanner::FileMetadata.get_title_from(entry.original).should eq entry.expected
      end
    end
  end
end
