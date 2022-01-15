require "bundler/setup"
require "lowkiq"
require "pry-byebug"

# to test their usage
Lowkiq.dump_error = -> (msg) { msg&.reverse }
Lowkiq.load_error = -> (msg) { msg&.reverse }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
