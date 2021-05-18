module Bravo

  # This class handles authorization data
  #
  class AuthData

    class << self

      require 'net/http'

      attr_accessor :environment

      # Fetches WSAA Authorization Data to build the datafile for the day.
      # It requires the private key file and the certificate to exist and
      # to be configured as Bravo.pkey and Bravo.cert
      #
      def fetch
        unless File.exists?(Bravo.pkey) || url_exist?(Bravo.pkey)
          raise "Archivo de llave privada no encontrado en #{ Bravo.pkey }"
        end

        unless File.exists?(Bravo.cert) || url_exist?(Bravo.cert)
          raise "Archivo certificado no encontrado en #{ Bravo.cert }"
        end

        unless File.exists?(todays_data_file_name)
          Bravo::Wsaa.login
        end

        YAML.load_file(todays_data_file_name).each do |k, v|
          Bravo.const_set(k.to_s.upcase, v)
        end
      end

      # Returns the authorization hash, containing the Token, Signature and Cuit
      # @return [Hash]
      #
      def auth_hash
        fetch
        { 'Token' => Bravo::TOKEN, 'Sign'  => Bravo::SIGN, 'Cuit'  => Bravo.cuit }
      end

      # Returns the right wsaa url for the specific environment
      # @return [String]
      #
      def wsaa_url
        raise 'Environment not sent to either :test or :production' unless Bravo::URLS.keys.include? environment
        Bravo::URLS[environment][:wsaa]
      end

      # Returns the right wsfe url for the specific environment
      # @return [String]
      #
      def wsfe_url
        raise 'Environment not sent to either :test or :production' unless Bravo::URLS.keys.include? environment
        Bravo::URLS[environment][:wsfe]
      end

      # Creates the data file name for a cuit number and the current day
      # @return [String]
      #
      def todays_data_file_name
        "/tmp/bravo_#{ Bravo.cuit }_#{ Time.new.strftime('%Y_%m_%d') }.yml"
      end

      private

      def url_exist?(url_string)
        url = URI.parse(url_string)
        req = Net::HTTP.new(url.host, url.port)
        req.use_ssl = (url.scheme == 'https')
        path = url.path if url.path.present?
        res = req.request_head(path || '/')
        res.code != "404" # false if returns 404 - not found
      rescue Errno::ENOENT
        false # false if can't find the server
      end
    end
  end
end
