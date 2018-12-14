require "json"
require "./scrypt"

module Flix::Authentication
  USERS_FILE    = File.join(Flix.config.config_location, "users.auth")
  MAX_WAIT_TIME =   3
  SALT_SIZE     =  32
  KEY_LENGTH    = 512 # Maximum allowed values

  class AllUsers
    # Allow serializing relevant data to file and back.
    # We could just include Serializable on AllUsers but this is just easier to
    # reason about.
    struct AllUsersSerialization
      include JSON::Serializable
      property users : Hash(String, Scrypt::Password)

      def initialize(@users); end
    end

    # where to save the file for later.
    property location : String

    # allow indexing an instance of AllUsers directly
    delegate "[]", to: @users
    delegate "[]?", to: @users
    delegate :delete, to: @users

    def initialize(at @location : String)
      @users = Hash(String, Scrypt::Password).new
      read
    end

    # allow initializing with an initial user. If you call
    # AllUsers.new(at: "/some/path"), and that file doesn't exist, it will raise
    # Errno::ENOENT (no such file). This will catch that and attempt to write
    # a new file in that case, with the only entry being the given username and
    # password.
    def initialize(at @location, user name, encrypted_password)
      @users = Hash(String, Scrypt::Password).new
      self[name] = encrypted_password
      begin
        read
      rescue e : Errno
        if e.errno == Errno::ENOENT
          begin
            File.delete lockfile
          rescue e : Errno
          end
          write
        else
          raise e
        end
      end
      write
    end

    def delete(user : User)
      delete user.name
    end

    def write
      write_to @location
    end

    private def write_to(file : IO)
      AllUsersSerialization.new(@users).to_json JSON::Builder.new io: file
      self
    end

    private def write_to(file : String)
      with_lock do
        File.open file, mode: "w" do |file|
          write_to file
        end
      end
    end

    def read
      with_lock do
        File.open @location do |file|
          merge! AllUsersSerialization.from_json file
        end
      end
      self
    end

    def merge!(other)
      if new_users = other.users
        @users.merge! new_users do |key, in_memory, from_file|
          in_memory
        end
      end
    end

    private def lockfile
      "#{@location}.lock"
    end

    private def with_lock
      waited = 0
      while File.exists? lockfile
        STDERR.puts "#{lockfile} exists, waiting for other process to be done"
        sleep 1
        waited += 1
        if waited > MAX_WAIT_TIME && MAX_WAIT_TIME > 0
          raise Errno.new(
            message: "#{lockfile} existed for longer than #{waited + 1} seconds",
            errno: Errno::EBUSY
          )
        end
      end
      File.touch lockfile
      rval = yield
      File.delete lockfile
      return rval
    end

    # read from the file, then merge in anything not present, and write the
    # newly merged hash back.
    def sync
      read
      write
    end
  end
end
