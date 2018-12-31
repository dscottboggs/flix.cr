#!/usr/bin/env crystal
require "../src/auth/scrypt"
require "colorize"
require "json"
require "option_parser"
require "file_utils"
include FileUtils
WARNING = %<#{"ARE YOU SURE".colorize(:red).mode(:bold)} #{"YOU WANT TO DELETE THE #{"ONLY".colorize(:red)} USER?".colorize.mode(:bold)}>

module UserModifications
  SALT_SIZE  =  32
  KEY_LENGTH = 512 # Maximum allowed values
  @@username = ""
  @@old_password = ""
  @@new_password = ""
  @@config_path = ""
  @@help_msg = ""

  def self.parse_args(args = ARGV)
    OptionParser.parse args do |parser|
      parser.banner = "Flix user modification scripts"

      parser.on "-f PATH", "--file PATH", "the path to the users file to change" do |path|
        @@config_path = path
      end
      parser.on "-u USER", "--user USER", "the name of the new user" do |user|
        @@username = user
      end
      parser.on "-p PASSWORD", "--password PASSWORD", "the password for the new user" do |pw|
        @@old_password = pw
      end
      parser.on "-o OLD_PW", "--old-password OLD_PW", "the old password when changing a password" do |pw|
        @@old_password = pw
      end
      parser.on "-n NEW_PW", "--new-password NEW_PW", "the new password when changing a password" do |pw|
        @@new_password = pw
      end
      parser.on("-h", "--help", "show this help message") { puts parser; exit 0 }
      @@help_msg = parser.to_s
    end
  end

  struct Users
    include JSON::Serializable
    property users : Hash(String, Scrypt::Password)
    forward_missing_to @users

    def initialize(@users); end

    def initialize
      @users = Hash(String, Scrypt::Password).new
    end

    def self.read(from filepath : String)
      File.open filepath do |file|
        self.from_json file
      end
    end

    def write(to filepath : String)
      File.open filepath, mode: "w" do |file|
        to_json file
      end
    end
  end

  def self.main
    action = ARGV.shift? # pop off the first arg
    parse_args
    abort message: @@help_msg if action.nil? || {"--help", "-h", "help"}.includes? action

    config_dir = File.dirname @@config_path
    mkdir config_dir unless File.exists? config_dir

    case action
    when "add", "new", "create"
      users = if File.exists? @@config_path
                Users.read @@config_path
              else
                Users.new
              end
      abort message: "\
        user #{@@username} already exists! Use the 'change' command to change an \
        existing user's password" if users[@@username]?
      users[@@username] = Scrypt::Password.create @@old_password, SALT_SIZE, KEY_LENGTH
      users.write @@config_path
    when .starts_with? "change"
      users = Users.read from: @@config_path
      current_pw = users[@@username]?
      abort message: "no such user #{@@username}" if current_pw.nil?
      abort message: "old password #{@@old_password} is incorrect, not changing password" unless current_pw == @@old_password
      users[@@username] = Scrypt::Password.create @@new_password, SALT_SIZE, KEY_LENGTH
      users.write to: @@config_path
    when "remove", "rm", "delete"
      users = Users.read from: @@config_path
      current_pw = users[@@username]?
      abort message: "no such user #{@@username}" if current_pw.nil?
      abort message: "password #{@@old_password} is incorrect, not deleting user" unless current_pw == @@old_password
      if users.size < 2
        print <<-HERE
          There is only one user left, "#{users.first_key}". If you choose to delete
          this user, the server will not start until you've created another.
          #{WARNING}
          (yes/NO)?:
        HERE
        if (input = STDIN.gets) && input.downcase.starts_with? "y"
          File.delete @@config_path
          exit
        else
          abort "not deleting last user!"
        end
      end
      users.delete @@username
      users.write @@config_path
    else
      abort message: %<Invalid action #{action}. Must be one of: "add", "new", "create", "change", "delete" "rm", or "remove"\n#{@@help_msg}>
    end
  end
end

UserModifications.main
