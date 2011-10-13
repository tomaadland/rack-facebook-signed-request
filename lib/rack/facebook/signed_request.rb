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
        if @options.size > 1
          return @options
        else
          @options.fetch(:secret)
        end
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

      # Parameter secret can be a single string or an options hash
      # if multiple apps we have to check all the keys for validity. Since facebook signed
      # requests can only de decodede with the correct secret key there is know way to know
      # beforehand. Beware also this is run on every request.
      def self.valid_signature?(secret, signature, data)
        signature = base64_url_decode(signature)
        if secret.is_a?(String)
          expected_signature = OpenSSL::HMAC.digest('SHA256', secret, data.tr("-_", "+/")) #TODO Is this tr supposed to be here?
          signature == expected_signature
        else
          secret.each do |s,v|
            return true if v[:secret] == expected_signature
          end
        end
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
