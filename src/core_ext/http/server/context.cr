# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

class HTTP::Server
  class Context
    alias UserHash = Hash(String, (String | Int32 | Nil | Bool))
    property current_user : UserHash?
  end
end
