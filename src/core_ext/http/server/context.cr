class HTTP::Server
  class Context
    alias UserHash = Hash(String, (String | Int32 | Nil | Bool))
    property current_user : UserHash?
  end
end
