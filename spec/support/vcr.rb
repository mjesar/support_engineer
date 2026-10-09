require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock

  # The key travels in the Authorization header, so without this filter it would
  # be written into the cassette and committed.
  config.filter_sensitive_data("<GROQ_API_KEY>") { ENV["GROQ_API_KEY"] }
end
