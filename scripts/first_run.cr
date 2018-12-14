require "../src/auth/all_users"
require "file_utils"
include FileUtils

username = "TEST USER"
password = Random::Secure.base64 15
begin
  mkdir "test_data/config"
rescue e : Errno
end
File.write "test_data/config/unencrypted_test_user_password", content: password

Flix::Authentication::AllUsers.new at: "test_data/config/users.auth",
  user: username,
  encrypted_password: Scrypt::Password.create(
    password,
    Flix::Authentication::KEY_LENGTH,
    Flix::Authentication::SALT_SIZE
  )
