describe Scanner::FileMetadata do
  describe ".get_title_from" do
    test_values = {
      "TestString"                                            => "Test String",
      "TestString.mp4"                                        => "Test String",
      "TestString-TheTestening.webm"                          => "Test String - The Testening",
      "Test_String.mp4"                                       => "Test String",
      "Test.String.mp4"                                       => "Test String",
      "Test.String.-.The.Testening.mp4"                       => "Test String - The Testening",
      "Title.For.Dot-Separated.Dir.With.Long.Final.Substring" => "Title For Dot-Separated Dir With Long Final Substring",
      "Test Filename with Spaces.mp4"                         => "Test Filename with Spaces",
    }
    test_values.each do |filename, title|
      it "returns #{title} for #{filename}" do
        Scanner::FileMetadata.get_title_from(filename).should eq title
      end
    end
  end
end
