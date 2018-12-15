require "../spec_helper"

class Flix::Authentication::AllUsers
  # enable access to private method outside of the class
  def __test_with_lock
    with_lock do
      yield
    end
  end
end

describe Flix::Authentication::AllUsers do
  describe "#with_lock" do
    it "works" do
      test_instance = Flix::Authentication::AllUsers.new at: File.join(TEST_CONFIG_DIR, "users.auth")
      File.exists?("#{test_instance.@location}.lock").should be_false
      test_instance.__test_with_lock do
        File.exists?("#{test_instance.@location}.lock").should be_true
      end
      File.exists?("#{test_instance.@location}.lock").should be_false
    end
    it "raises an exception after a timeout" do
      test_instance = Flix::Authentication::AllUsers.new at: File.join(TEST_CONFIG_DIR, "users.auth")
      File.touch "#{test_instance.@location}.lock"
      start = Time.monotonic
      expect_raises Exception do
        test_instance.__test_with_lock do
          "nothing, it won't work anyway"
        end
      end
      (Time.monotonic - start).should be > Flix::Authentication::MAX_WAIT_TIME.seconds
      File.delete "#{test_instance.@location}.lock"
    end
  end

  describe "#read/#write" do
    # TODO: improve
    # just check that the file has the expected state, `#read()` is called in
    # the `#initialize()` method.
    it "reads the expected state from the example file" do
      read_pw = Flix::Authentication::AllUsers.new(
        at: File.join(TEST_CONFIG_DIR, "users.auth")
      )["TEST USER"]
      read_pw.should be_a Scrypt::Password
      read_pw.should eq File.read(File.join(TEST_CONFIG_DIR, "unencrypted_test_user_password")).chomp
    end
  end
end
