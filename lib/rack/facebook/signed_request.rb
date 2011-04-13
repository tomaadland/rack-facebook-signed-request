require 'openssl'
require 'base64'
require 'yajl'

#
# Gemified and borrowed heavily from Ole Riesenberg:
# http://oleriesenberg.com/2010/07/22/facebook-graph-api-with-fbml-canvas-apps.html
#
module Rack
  module Facebook
    class SignedRequest

      def initialize(app, options, &condition)
        @app = app
        @condition = condition
        @options = options
      end


      def secret
        @options.fetch(:secret)
      end


      def call(env)
        request = Rack::Request.new(env)

        signed_request = request.params['signed_request']
        unless signed_request.nil?
          signature, signed_params = signed_request.split('.')

          unless self.class.valid_signature?(secret, signature, signed_params)
            return Rack::Response.new(["Invalid signature"], 400).finish
          end

          signed_params = self.class.json_from_payload(signed_params)

          # add JSON params to request
          request.params['facebook'] = {}
          signed_params.each do |k,v|
            request.params['facebook'][k] = v
          end
        end
        @app.call(env)
      end


      def self.json_from_payload(payload)
        Yajl::Parser.new.parse(base64_url_decode(payload))
      end


      def self.valid_signature?(secret, signature, data)
        signature = base64_url_decode(signature)
        expected_signature = OpenSSL::HMAC.digest('SHA256', secret, data.tr("-_", "+/")) #TODO Is this tr supposed to be here?
        signature == expected_signature
      end


      def self.base64_url_decode(str)
        str = str + "=" * (6 - str.size % 6) unless str.size % 6 == 0
        Base64.decode64(str.tr('-_', '+/'))
      end


      def self.base64_url_encode(str)
        Base64.encode64(str).tr('+/', '-_').chomp.gsub(/=+$/, '')
      end


    end
  end
end
