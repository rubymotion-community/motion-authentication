module Motion
  class Authentication
    class DeviseSimpleTokenAuth
      class << self
        def sign_in(sign_in_url, params, &block)
          HTTP.post(sign_in_url, json: { user: params }) do |response|
            if response.success?
              store_auth_tokens(response.object)
            end
            block.call(response)
          end
        end

        def sign_up(sign_up_url, params, &block)
          HTTP.post(sign_up_url, json: { user: params }) do |response|
            if response.success?
              store_auth_tokens(response.object)
            end
            block.call(response)
          end
        end

        def store_auth_tokens(data)
          MotionKeychain.set :auth_email, data["email"]
          MotionKeychain.set :auth_token, data["token"]
        end

        def authorization_header
          token = MotionKeychain.get :auth_token
          email = MotionKeychain.get :auth_email
          %Q|Token token="#{token}", email="#{email}"|
        end

        def signed_in?
          !! MotionKeychain.get(:auth_token)
        end

        def sign_out(&block)
          MotionKeychain.remove :auth_email
          MotionKeychain.remove :auth_token
          block.call
        end
      end
    end
  end
end
