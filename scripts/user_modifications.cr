#!/usr/bin/env crystal
require "../src/config/configuration_class"
require "../src/auth/all_users"
require "colorize"
require "option_parser"
WARNING = %<#{"ARE YOU SURE".colorize(:red).mode(:bold)} #{"YOU WANT TO DELETE THE #{"ONLY".colorize(:red)} USER?".colorize.mode(:bold)}>

enum Actions
  Add
  ChangePassword
  Remove
  def self.from_s(string)
    case string.downcase
    when "add" then Add
    when .starts_with?("change") then ChangePassword
    when "rm", "remove" then Remove
    else
      abort %<Invalid action #{string}. Must be one of: "add", "change", "rm", or "remove">
    end
  end
end

username = ""
old_password = ""
new_password = ""
config_path = ""
args = ARGV
action = Actions.from_s args.shift

OptionParser.parse args do |parser|
  parser.banner "Flix user modification scripts"

  parser.on "-f CONFIG", "--config CONFIG", "the path to the config file to change" do |path|
    config_path = path
  end
  parser.on "-u USER", "--user USER", "the name of the new user" do |user|
    username = user
  end
  parser.on "-p PASSWORD", "--password PASSWORD", "the password for the new user" do |pw|
    old_password = pw
  end
  parser.on "-o OLD_PW", "--old-password OLD_PW", "the old password when changing a password" do |pw|
    old_password = pw
  end
  parser.on "-n NEW_PW", "--new-password NEW_PW", "the new password when changing a password" do |pw|
    new_password = pw
  end
end

Flix.config = Flix::Configuration.new config_location: options.config, port: 0

case action
when Actions::Add
  AllUsers.new at: config_path,
    user: username,
    encrypted_password: Flix::Authentication.encrypt old_password
when Actions::ChangePassword
  users = Flix::Authentication::AllUsers.new at: config_location
  user = User.new(username)
  if user.is_authenticated_by? old_password
    user.set_password to: new_password
  end
  users[user.name] = user
  users.write
when Actions::Remove
  users = Flix::Authentication::AllUsers.new at: config_location
  if (user = User.new(options.username)).is_authenticated_by? options.password
    if users.size < 2
      print <<-HERE
        There is only one user left, "#{user.name}". If you choose to delete
        this user, the server will not start until you've created another.
        #{WARNING}
        (yes/NO)?:
      HERE
      unless (input = STDIN.gets) && input.downcase.starts_with? "y"
        raise "not deleting last user!"
      end
    end
    users.delete user
  end
end
