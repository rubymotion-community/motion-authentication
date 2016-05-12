class Motion
  class Authentication
    class << self
      attr_accessor :current_user

      def strategy(val = nil)
        @strategy = val unless val.nil?
        @strategy ||= DeviseTokenAuth
      end

      def sign_in_url(val = nil)
        @sign_in_url = val unless val.nil?
        @sign_in_url
      end

      def sign_up_url(val = nil)
        @sign_up_url = val unless val.nil?
        @sign_up_url
      end

      def sign_in(params, &block)
        strategy.sign_in(sign_in_url, params, &block)
      end

      def sign_up(params, &block)
        strategy.sign_up(sign_up_url, params, &block)
      end


      def authorization_header
        strategy.authorization_header
      end

      def signed_in?
        strategy.signed_in?
      end

      def sign_out(&block)
        strategy.sign_out(&block)
      end
    end
  end
end
