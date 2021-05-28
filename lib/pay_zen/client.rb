# frozen_string_literal: true

# PayZen payments gateway
module PayZen; end

API_PATH = '/api-payment/V4'

# Client for connecting to the PayZen REST API
class PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    @base_url = base_url
    @username = username
    @password = password
  end

  protected

  def post(rel_url, payload)
    require 'uri'
    require 'net/http'
    require 'json'

    uri = URI(File.join(base_url, API_PATH, rel_url))
    headers = {
      'Authorization' => authorization_header,
      'Content-Type' => 'application/json'
    }

    res = Net::HTTP.post(uri, payload.to_json, headers)
    raise ::PayzenError unless res.is_a?(Net::HTTPSuccess)

    json = JSON.parse(res.body)
    raise ::PayzenError, json['answer']['errorMessage'] if json['status'] == 'ERROR'

    json
  end

  def base_url
    @base_url || Setting.get('payzen_endpoint')
  end

  def authorization_header
    username = @username || Setting.get('payzen_username')
    password = @password || Setting.get('payzen_password')

    credentials = Base64.strict_encode64("#{username}:#{password}")
    "Basic #{credentials}"
  end
end
