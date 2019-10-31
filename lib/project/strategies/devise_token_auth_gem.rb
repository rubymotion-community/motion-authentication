module Motion
  class Authentication
    class DeviseTokenAuth
      class << self
        def sign_in(sign_in_url, params, &block)
          HTTP.post(sign_in_url, json: params) do |response|
            if response.success?
              store_auth_tokens(response.object, response.headers)
            end
            block.call(response)
          end
        end

        def sign_up(sign_up_url, params, &block)
          HTTP.post(sign_up_url, json: params) do |response|
            if response.success?
              store_auth_tokens(response.object, response.headers)
            end
            block.call(response)
          end
        end

        def store_auth_tokens(response, headers)
          MotionKeychain.set :auth_uid, headers["uid"]
          MotionKeychain.set :auth_token, headers["access-token"]
          MotionKeychain.set :auth_client, headers["client"]
          serialized_response = ""
          response["data"].each do |key, value|
            case key
            when "assets"
              value.each do |eachasset|
                serialized_response << eachasset["name"] + "·" + eachasset["qty"].to_s + ","
              end
            else
              serialized_response << key + "·" + value.to_s + ","
            end
          end
          MotionKeychain.set :current_user, serialized_response
        end

        def set_current_user
          deserialize(MotionKeychain.get :current_user)
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

        def deserialize(mystring, arr_sep=',', key_sep='·')
          array = mystring.split(arr_sep)
          hash = {}
          array.each do |e|
            key_value = e.split(key_sep)
            hash[key_value[0]] = key_value[1]
          end
          return hash
        end
      end
    end
  end
end
