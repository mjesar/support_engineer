require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Include the body so a changed prompt or question forces a re-record instead
  # of silently replaying an old answer.
  config.default_cassette_options = { match_requests_on: %i[method uri body] }

  # The key travels in the Authorization header, so without this filter it would
  # be written into the cassette and committed.
  config.filter_sensitive_data("<GROQ_API_KEY>") { RubyLLM.config.openai_api_key }
end

# RubyLLM refuses to build a chat without a key, even when VCR only replays.
# This lets anyone run the specs from the cassettes without a Groq account.
RubyLLM.config.openai_api_key ||= "replay-only-key"
