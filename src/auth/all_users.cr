require "json"
require "./scrypt"

module Flix::Authentication
  LOCKFILE      = File.join(Flix.config.config_location, "users.auth.lock")
  USERS_FILE    = File.join(Flix.config.config_location, "users.auth")
  MAX_WAIT_TIME =   3
  SALT_SIZE     =  32
  KEY_LENGTH    = 512 # Maximum allowed values

  class AllUsers < Hash(String, Scrypt::Password)
    property location : String

    def initialize(at @location)
      super()
      read
    end

    def write
      write_to @location
    end

    protected def write_to(file : IO)
      JSON::Builder.new io: file do |builder|
        builder.object do
          builder.field "users" do
            to_json(builder)
          end
        end
      end
    end

    protected def write_to(file : String)
      with_lock do
        File.open file, mode: "w" do |file|
          write_to file
        end
      end
    end

    def read
      with_lock do
        File.open @location do |file|
          merge! Hash(String, Scrypt::Password).from_json(file) do |key, in_memory, from_file|
            in_memory
          end
        end
      end
    end

    private def with_lock
      waited = 0
      while File.exists? LOCKFILE
        Flix.logger.warn "#{LOCKFILE} exists, waiting for other process to be done"
        sleep 1
        waited += 1
        if waited > MAX_WAIT_TIME && MAX_WAIT_TIME > 0
          raise Errno.new(
            message: "#{LOCKFILE} existed for longer than #{waited} seconds, bailing.",
            errno: Errno::EBUSY
          )
        end
      end
      File.open(LOCKFILE, "w").close
      yield
      File.delete LOCKFILE
    end

    # read from the file, then merge in anything not present, and write the
    # newly merged hash back.
    def sync
      read
      write
    end
  end
end
