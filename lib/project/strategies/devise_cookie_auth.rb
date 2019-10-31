module Motion
  class Authentication
    class DeviseCookieAuth
      class << self
        def sign_in(sign_in_url, params, &block)
          get_csrf_token(sign_in_url) do |param_name, token|
            namespace = params[:namespace] || :user
            HTTP.post(sign_in_url, form: { namespace => params, param_name => token }, follow_redirects: false) do |response|
              if response.status_code == 302 # assume success due to redirect
                cookie = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookiesForURL(NSURL.URLWithString(sign_in_url)).first
                store_session_cookie(cookie)
                block.call(true)
              else # didn't redirect, must be invalid credentials
                block.call(false)
              end
            end
          end
        end

        def get_csrf_token(sign_in_url, &block)
          HTTP.get(sign_in_url) do |response|
            doc = Motion::HTML.parse(response.body)
            param_meta_tag = doc.query('head meta[name="csrf-param"]').first
            token_meta_tag = doc.query('head meta[name="csrf-token"]').first
            if param_meta_tag && token_meta_tag
              param_name = param_meta_tag['content']
              token = token_meta_tag['content']
              block.call(param_name, token)
            else
              mp 'Couldnt parse CSRF token from HTML'
            end
          end
        end

        def store_session_cookie(cookie)
          MotionKeychain.set :session_cookie, JSON.generate(properties: cookie.properties)
        end

        def signed_in?
          MotionKeychain.get(:session_cookie) && restore_session
        end

        def restore_session
          json = MotionKeychain.get(:session_cookie)
          data = JSON.parse(json)
          cookie = NSHTTPCookie.cookieWithProperties(data['properties'])
          NSHTTPCookieStorage.sharedHTTPCookieStorage.setCookie(cookie)
        end

        def sign_out(&block)
          MotionKeychain.remove :session_cookie
          block.call
        end
      end
    end
  end
end
