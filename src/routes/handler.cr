class Flix::Handler < Kemal::Handler
  macro skip_other_routes
    return call_next(env) unless only_match? env
  end
end
