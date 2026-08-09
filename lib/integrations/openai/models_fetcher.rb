module Integrations::Openai::ModelsFetcher
  TIMEOUT_SECONDS = 5
  CACHE_TTL = 10.minutes
  CACHE_KEY_PREFIX = 'openai_remote_models'.freeze

  class << self
    def fetch
      endpoint = configured_endpoint
      api_key = configured_api_key
      return nil if endpoint.blank? || api_key.blank?

      Rails.cache.fetch(cache_key(endpoint), expires_in: CACHE_TTL) do
        fetch_from_api(endpoint, api_key)
      end
    end

    def api_base(endpoint = configured_endpoint)
      return nil if endpoint.blank?

      "#{endpoint.to_s.chomp('/')}/v1"
    end

    private

    def configured_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence
    end

    def configured_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.presence
    end

    def cache_key(endpoint)
      "#{CACHE_KEY_PREFIX}:#{Digest::SHA256.hexdigest(endpoint.to_s)}"
    end

    def fetch_from_api(endpoint, api_key)
      connection = Faraday.new do |f|
        f.options.timeout = TIMEOUT_SECONDS
        f.options.open_timeout = TIMEOUT_SECONDS
      end

      response = connection.get("#{api_base(endpoint)}/models") do |req|
        req.headers['Authorization'] = "Bearer #{api_key}"
      end

      return nil unless response.success?

      parse_models(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.warn("[openai-models-fetcher] #{e.class}: #{e.message}")
      nil
    end

    def parse_models(body)
      payload = JSON.parse(body)
      ids = Array(payload['data']).filter_map { |item| item['id'].presence }.uniq
      return nil if ids.empty?

      ids.map do |id|
        {
          id: id,
          display_name: id,
          provider: 'openai',
          credit_multiplier: 1
        }
      end
    end
  end
end
