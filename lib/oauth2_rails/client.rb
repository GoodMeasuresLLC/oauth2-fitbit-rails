require 'oauth2_rails/base'
require 'oauth2_rails/user'

module Oauth2Rails
  class Client < Base

    def initialize(user, options = {})
      super(options)
      @user = user
    end

    def api_call(destination)
      begin
        call(:get, destination, user: @user.access_token)
      rescue Oauth2Rails::Errors::Unauthorized
        refresh
        call(:get, destination, user: @user.access_token)
      end
    end

    def api_post(destination)
      begin
        call(:post, destination, user: @user.access_token)
      rescue Oauth2Rails::Errors::Unauthorized
        refresh
        call(:post, destination, user: @user.access_token)
      end
    end

    def api_delete(destination)
      begin
        call(:delete, destination, user: @user.access_token)
      rescue Oauth2Rails::Errors::Unauthorized
        refresh
        call(:delete, destination, user: @user.access_token)
      end
    end

    def refresh(refresh_token=@user.refresh_token)
      response = call(:post, "#{@token_path}?grant_type=refresh_token&refresh_token=#{refresh_token}")
      @user.attributes = {
        access_token: response.access_token,
        refresh_token: response.refresh_token,
        expiry: Time.now + response.expires_every
      }
      @user.save(:validate => false)
      @user
    end

  end
end
