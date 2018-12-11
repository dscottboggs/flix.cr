module Flix::Authentication
  TOKEN_SIZE = 512

  struct Token
    alias TokenType = StaticArray(UInt8, TOKEN_SIZE)
    @data : TokenType

    private def initialize(@data : TokenType); end

    def initialize
      @data = TokenType.new do
        Random::Secure.rand UInt8::MAX
      end
    end

    def initialize(encoded string : String)
      data = Base64.decode string
      @data = TokenType.new do |i|
        data[i]? || return
      end
    end

    def to_s
      Base64.urlsafe_encode @data
    end
  end
end
