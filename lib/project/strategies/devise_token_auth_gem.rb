module Motion
  class Authentication
    class DeviseTokenAuthGem
      class << self
        def sign_in(sign_in_url, params, &block)
          AFMotion::JSON.post(sign_in_url, params) do |response|
            if response.success?
              store_auth_tokens(response,response.operation.response.allHeaderFields)
            end
            block.call(response)
          end
        end

        def sign_up(sign_up_url, params, &block)
          AFMotion::JSON.post(sign_up_url, params) do |response|
            if response.success?
              store_auth_tokens(response.operation.response.allHeaderFields)
            end
            block.call(response)
          end
        end

        def store_auth_tokens(body,headers)
          MotionKeychain.set :auth_uid, headers["uid"]
          MotionKeychain.set :auth_token, headers["access-token"]
          MotionKeychain.set :auth_client, headers["client"]
          MotionKeychain.set :current_user, body
        end

        def set_current_user
          MotionKeychain.get :current_user
        end

        def authorization_header
          token = MotionKeychain.get :auth_token
          uid = MotionKeychain.get :auth_uid
          client = MotionKeychain.get :auth_client
          {"access-token" => token, "uid" => uid, "client" => client }
        end

        def signed_in?
          !! MotionKeychain.get(:auth_token)
        end

        def sign_out(&block)
          MotionKeychain.remove :auth_uid
          MotionKeychain.remove :auth_token
          MotionKeychain.remove :auth_client
          MotionKeychain.remove :current_user
          block.call
        end
      end
    end
  end
end
