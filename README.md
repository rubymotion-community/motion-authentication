# motion-authentication

`motion-authentication` aims to provide a simple, standardized authentication helper for common authentication strategies.

Currently, this library only supports iOS, but could easily support other platforms. Please submit an issue (or PR :D) for the platform you would like to support.

Need authorization? Use [`motion-authorization`](https://github.com/rubymotion-community/motion-authorization)!

## Installation

Add this line to your application's `Gemfile`, then run `bundle install`:

    gem 'motion-authentication', '~> 2.0'

Next, run `rake pod:install` to install the CocoaPod dependencies.

## Usage

Start by subclassing `Motion::Authentication` to create your own `Auth` class. Specify your authentication strategy and your sign in URL:

```ruby
class Auth < Motion::Authentication
  strategy DeviseTokenAuth
  sign_in_url "https://example.com/api/v1/users/sign_in"
end
```

Available strategies:

* `DeviseCookieAuth` - This strategy supports the default way of authenticating with Devise, just as if you were submitting the sign in form using a web browser. It works by making an initial request to fetch the authenticity token, then submits the `email` and `password`, then stores the resulting cookie for authenticating future requests. If your user model has a different name (i.e. `AdminUser`), pass along the `namespace` option (i.e. `namespace: 'admin_user'`) when calling `sign_in`. Otherwise, namespace defaults to `:user`.

* `DeviseTokenAuth` - This authentication strategy is based on [José Valim's example gist](https://gist.github.com/josevalim/fb706b1e933ef01e4fb6) and is also in the format that Ember Simple Auth Devise adapter expects ([tutorial](http://romulomachado.github.io/2015/09/28/using-ember-simple-auth-with-devise.html))

  This strategy takes `email` and `password`, makes a POST request to the `sign_in_url`, and expects the response to include `email` and `token` keys in the JSON response object.

* `DeviseTokenAuthGem` - This authentication strategy is compatible with the current version of the devise_auth_token gem at https://github.com/lynndylanhurley/devise_token_auth

  Signing up: this strategy takes `email`, `password` and `password_confirmation`, makes a POST request to the `sign_up_url`, and expects the response to include `uid`, `access-token` and `client` keys in the response object headers.

  Signing in: this strategy takes `email` and `password`, makes a POST request to the `sign_in_url`, and expects the response to include `uid`, `access-token` and `client` keys in the response object headers.

### `.sign_in`

Using your `Auth` class, call `.sign_in` and pass a hash of credentials:

```ruby
Auth.sign_in(email: email, password: password) do |result|
  if result.success?
    # authentication successful!
  else
    app.alert "Invalid email or password"
  end
end
```

### `.signed_in?`

You can check if an auth token has previously been stored by using `signed_in?`. For example, in your App Delegate, you might want to open your sign in screen when the app is opened:

```ruby
def on_load(options)
  if Auth.signed_in?
    open DashboardScreen
  else
    open SignInScreen
  end
end
```

### `.authorization_header`

After signing in, assuming you are using one of the token auth strategies, you will want to configure your API client to use your auth token in your API requests in an authorization header. Call `.authorization_header` to return the header value specific to the strategy that you are using. Two common places would be upon sign in, and when your app is launched.

```ruby
# app_delegate.rb
def on_load(options)
  if Auth.signed_in?
    MyApiClient.update_auth_header(Auth.authorization_header)
    # ...
  end
end

# sign_in_screen.rb
def on_load(options)
  Auth.sign_in(data) do |result|
    if result.success?
      MyApiClient.update_auth_header(Auth.authorization_header)
      # ...
    end
  end
end
```

#### Note on `DeviseTokenAuthGem` strategy

The `devise_token_auth` gem requires all authenticated API calls to include the keys `uid`, `access-token` and `client` in the HTTP headers. Calling `.authorization_header` will return a hash with the proper key/value pairs. To include these as headers in all calls we recommend setting up your API client as follows:

```ruby
ApiClient.update_authorization_header(Auth.authorization_header)

class ApiClient
  class << self
    def client
      @client ||= AFMotion::SessionClient.build("http://localhost:3000/") do
        response_serializer :json
        header "Content-Type", "application/json"
      end
    end

    def update_authorization_header(auth_headers_hash)
      auth_headers_hash.each do |key, value|
        client.headers[key] = value
      end
    end
  end
end
```

### `.sign_out`

At some point, you're going to need to sign out. This method will clear the stored auth token, but also allows you to pass a block to be called after the token has been cleared.

```ruby
Auth.sign_out do
  open HomeScreen
end
```

### `.current_user`

`motion-authentication` provides a `current_user` attribute. It has no effect on authentication, so you can do whatever you want with it.

```ruby
Auth.sign_in(data) do |result|
  if result.success?
    Auth.current_user = User.new(result.object)
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
