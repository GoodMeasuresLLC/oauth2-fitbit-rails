require 'oauth2_rails/errors'

module Oauth2Rails
  class Base

    def initialize(options = {})
      @oauth_id       = options[:oauth_id]       || OAUTH2_RAILS_ID
      @oauth_secret   = options[:oauth_secret]   || OAUTH2_RAILS_SECRET
      @redirect_uri   = options[:redirect_uri]   || OAUTH2_RAILS_CALLBACK
      @authorize_site = options[:authorize_site] || 'https://www.fitbit.com'
      @authorize_path = options[:authorize_path] || '/oauth2/authorize'
      @api_site       = options[:api_site]       || 'https://api.fitbit.com'
      @token_path     = options[:token_path]     || '/oauth2/token'
      @scope          = options[:scope]          || 'activity heartrate location nutrition profile settings sleep social weight'
    end

    def connection(url)
      Faraday.new(url: url) do |faraday|
        faraday.request  :url_encoded
#        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    def call(action, destination, options = {})
      user = options[:user]
      site = options[:site] || @api_site

      if user
        auth_header = "Bearer #{user}"
      else
        encoded = Base64.strict_encode64("#{@oauth_id}:#{@oauth_secret}")
        auth_header = "Basic #{encoded}"
      end

      call = connection(site).send(action) do |req|
        req.url destination
        req.headers['Content-Type']   = 'application/x-www-form-urlencoded'
        req.headers['Authorization']  = auth_header
        req.body = options[:body]
      end

      response = Response.new(call)
      case response.status
        when 400 ; raise Oauth2Rails::Errors::BadRequest,      "400 #{response.error_message}"
        when 404 ; raise Oauth2Rails::Errors::NotFound,        "404 #{response.error_message}"
        when 409 ; raise Oauth2Rails::Errors::Conflict,        "409 #{response.inspect}"
        when 500 ; raise Oauth2Rails::Errors::InternalServer,  "500 #{response.error_message}"
        when 502 ; raise Oauth2Rails::Errors::BadGateway,      "502 #{response.error_message}"
        when 401 ; raise Oauth2Rails::Errors::Unauthorized,    "401 #{response.error_message}"
        else ; response
      end

    end

  end
end
