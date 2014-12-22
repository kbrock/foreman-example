$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

begin
  require 'pry'
rescue LoadError
end

require 'yaml'
yaml=File.exist?('foreman.yml') ? YAML.load_file('foreman.yml')['creds'] : {}
FOREMAN = {
  :base_url   => ENV["FOREMAN_HOSTNAME"] || yaml["base_url"],
  :username   => ENV["FOREMAN_USERNAME"] || yaml["username"],
  :password   => ENV["FOREMAN_PASSWORD"] || yaml["password"],
  :verify_ssl => false
}

require 'vcr'
require 'rspec/autorun'

RSpec.configure do |c|
  # c.extend VCR::RSpec::Macros
end
# vcr helper
RECORD = {:record => :new_episodes }
# :vcr => use_cassette("x", RECORD)
def use_cassette(name, options={})
  options.merge(:cassette_name => name)
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock

  c.allow_http_connections_when_no_cassette = false
  c.default_cassette_options = {
    :allow_unused_http_interactions => false
  }
  c.configure_rspec_metadata!

  #c.debug_logger = File.open(Rails.root.join("log", "vcr_debug.log"), "w")
  #c.debug_logger = File.open(File.join(ENV['CC_BUILD_ARTIFACTS'], "vcr_debug.log"), "w") if ENV['CC_BUILD_ARTIFACTS']
end

require 'manageiq_foreman'
