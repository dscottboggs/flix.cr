# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.

class HTTP::Server
  class Context
    alias UserHash = Hash(String, (String | Int32 | Nil | Bool))
    property current_user : UserHash?

    # Returns true if the user is found or if
    # Flix::Configuration.allow_unauthorized is set. Otherwise, sets the status
    # to *403 Forbidden* and returns false.
    def user_found?
      if current_user.try(&.["name"]?)
        true
      else
        response.status_code = 403
        false
      end
    end
  end
end
