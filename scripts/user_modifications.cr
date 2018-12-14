require "../src/config/configuration_class"
require "../src/auth/all_users"
require "cli"
require "colorize"

class UserModifier < Cli::Supercommand
  include Flix::Authentication

  UsernameOptionAliases = %w<--name --named -u --user --username>
  PasswordOptionAliases = %w<--pw --password --unencrypted-password>

  class CommonCommands < Cli::Command
    class Options
      # string "--port"
      # bool %w<d debug>
      # string "--webroot"
      # string "--processes"
      string %w<--config-location -c --config>
    end

    macro configure
      Flix.config = Flix::Configuration.new config_location: options.config, port: 0
    end
  end

  class Add < CommonCommands
    class Options
      string UsernameOptionAliases
      string PasswordOptionAliases
    end

    def run
      configure
      AllUsers.new at: options.config,
        user: options.username,
        encrypted_password: Flix::Authentication.encrypt options.password
    end
  end

  class ChangePassword < CommonCommands
    class Options
      string UsernameOptionAliases
      string %w<--old-pw -o --old-password>
      string %w<--new-pw -n --new-password>
    end

    def run
      configure
      users = Flix::Authentication::AllUsers.new at: config_location
      user = User.new(options.username)
      if user.is_authenticated_by? options.old_password
        user.set_password to: new_password
      end
      users[user.name] = user
      users.write
    end
  end

  class Remove < CommonCommands
    class Options
      string UsernameOptionAliases
      string PasswordOptionAliases
      bool %w<-f --force --delete-last-user>
    end

    WARNING = %<#{"ARE YOU SURE".colorize(:red).mode(:bold)} #{"YOU WANT TO DELETE THE #{"ONLY".colorize(:red)} USER?".colorize.mode(:bold)}>

    def run
      configure
      users = Flix::Authentication::AllUsers.new at: config_location
      if (user = User.new(options.username)).is_authenticated_by? options.password
        print <<-HERE
          There is only one user left, "#{user.name}". If you choose to delete
          this user, the server will not start until you've created another. #{WARNING}
          (yes/NO)?:
        HERE
        unless (input = STDIN.gets) && (input.match /y(es)?/i)
          raise "not deleting last user!"
        end
        users.delete user
      end
    end
  end
end
