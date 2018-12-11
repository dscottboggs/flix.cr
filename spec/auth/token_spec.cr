describe Flix::Authentication::Token do
  it "correctly serializes and deserializes with Base64" do
    test_token = Flix::Authentication::Token.new
    test_token.to_s.should eq Flix::Authentication::Token.new test_token.to_s
  end
  it "generates 1024 truly random tokens." do
    test_values = Array(Flix::Authentication::Token).new(1 << 1024) do
      Flix::Authentication::Token.new
    end
    test_values.size.should eq test_values.uniq.size
  end
end
