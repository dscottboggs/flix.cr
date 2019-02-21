# Flix -- A media server in the Crystal Language with Kemal.cr
# Copyright (C) 2018 D. Scott Boggs
# See LICENSE.md for the terms of the AGPL under which this software can be used.
require "json"
require "./scrypt"
require "../flix"

module Flix::Authentication
  USERS_FILE    = File.join(Flix.config.config_location, "users.auth") # Where the users will be stored on disk
  MAX_WAIT_TIME =   3                                                  # how long to wait before raising an exception when the lock file exists
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

    # allow indexing an instance of AllUsers directly, as with other methods of
    # Hash, like #size and #delete
    delegate "[]", "[]?", "[]=", :delete, :size, to: @users

    # I think this is not working due to a bug in crystal --
    # foward_missing_to @users

    # :nodoc:
    def initialize(@users)
      # a hack for testing
      @location = ""
    end

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

    # Serialize the collection and write it to the file at `#location`.
    # Chainable
    def write
      write_to @location
    end

    # Serialize the collection and write it to the given IO.
    # Chainable
    private def write_to(file : IO)
      builder = JSON::Builder.new io: file
      builder.document do
        AllUsersSerialization.new(@users).to_json(builder)
      end
      self
    end

    # Serialize the collection and write it to the file at the given filepath.
    # Chainable
    private def write_to(file : String)
      with_lock do
        File.open file, mode: "w" do |file|
          write_to file
        end
      end
    end

    # Read the collection in from @location, deserialize it, and merge the
    # results with the existing entries.
    # Chainable
    def read
      with_lock do
        File.open @location do |file|
          merge! AllUsersSerialization.from_json file
        end
      end
      self
    end

    # Merge the entries from other into self.
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

    # Checks for the existence of a lockfile, waits MAX_WAIT_TIME, then raises
    # an exception. If the lockfile doesn't exist, it's created, and then the
    # block is yielded, then the lockfile is deleted and the result of the block
    # returned.
    # This could be improved by writing the current PID to the lockfile, then
    # checking if the PID is alive before assuming the lockfile is valid.
    #
    # To use:
    # ```
    # with_lock do
    #   # some stuff
    #   with_lock do
    #     # an exception is raised here after a few seconds.
    #   end
    # end
    # ```
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
    # newly merged data back.
    def sync
      read
      write
    end
  end
end
