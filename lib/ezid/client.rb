require "net/http"

require_relative "configuration"
require_relative "requests"
require_relative "response"
require_relative "session"
require_relative "metadata"
require_relative "identifier"
require_relative "error"
require_relative "status"

module Ezid
  #
  # EZID client
  #
  # @api public
  #
  class Client

    include Requests

    # ezid-client gem version (e.g., "0.8.0")
    VERSION = File.read(File.expand_path("../../../VERSION", __FILE__)).chomp

    # EZID API version
    API_VERSION = "2"

    class << self
      # Configuration reader
      def config
        @config ||= Configuration.new
      end

      # Yields the configuration to a block
      # @yieldparam [Ezid::Configuration] the configuration
      def configure
        yield config
      end

      # Verbose version string
      # @return [String] the version
      def version
        "ezid-client #{VERSION} (EZID API Version #{API_VERSION})"
      end
    end

    attr_reader :user, :password, :host, :port, :use_ssl

    def initialize(opts = {})
      @host = opts[:host] || config.host
      @use_ssl = opts.fetch(:use_ssl, config.use_ssl)
      @port = (opts[:port] || config.port || (use_ssl ? 443 : 80)).to_i
      @user = opts[:user] || config.user
      @password = opts[:password] || config.password
      if block_given?
        login
        yield self
        logout
      end
    end

    def inspect
      "#<#{self.class.name} connection=#{connection.inspect} " \
        "user=\"#{user}\" session=#{logged_in? ? 'OPEN' : 'CLOSED'}>"
    end

    # The client configuration
    # @return [Ezid::Configuration] the configuration object
    def config
      self.class.config
    end

    # The client logger
    # @return [Logger] the logger
    def logger
      @logger ||= config.logger
    end

    # The client session
    # @return [Ezid::Session] the session
    def session
      @session ||= Session.new
    end

    # Open a session
    # @raise [Ezid::Error]
    # @return [Ezid::Client] the client
    def login
      if logged_in?
        logger.info("Already logged in, skipping login request.")
      else
        execute LoginRequest
      end
      self
    end

    # Close the session
    # @return [Ezid::Client] the client
    def logout
      if logged_in?
        execute LogoutRequest
      else
        logger.info("Not logged in, skipping logout request.")
      end
      self
    end

    # @return [true, false] whether the client is logged in
    def logged_in?
      session.open?
    end

    # @param identifier [String] the identifier string to create
    # @param metadata [String, Hash, Ezid::Metadata] optional metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def create_identifier(identifier, metadata=nil)
      execute CreateIdentifierRequest, identifier, metadata
    end

    # @param shoulder [String] the shoulder on which to mint a new identifier
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def mint_identifier(shoulder=nil, metadata=nil)
      shoulder ||= config.default_shoulder
      raise Error, "Shoulder missing -- cannot mint identifier." unless shoulder
      execute MintIdentifierRequest, shoulder, metadata
    end

    # @param identifier [String] the identifier to modify
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def modify_identifier(identifier, metadata)
      execute ModifyIdentifierRequest, identifier, metadata
    end

    # @param identifier [String] the identifier to retrieve
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def get_identifier_metadata(identifier)
      execute GetIdentifierMetadataRequest, identifier
    end

    # @param identifier [String] the identifier to delete
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def delete_identifier(identifier)
      execute DeleteIdentifierRequest, identifier
    end

    # @param subsystems [Array]
    # @raise [Ezid::Error]
    # @return [Ezid::Status] the status response
    def server_status(*subsystems)
      execute ServerStatusRequest, *subsystems
    end

    def connection
      @connection ||= build_connection
    end

    private

    def build_connection
      conn = Net::HTTP.new(host, port)
      conn.use_ssl = use_ssl
      conn
    end

    def handle_response(response, request_name)
      log_level = response.error? ? Logger::ERROR : Logger::INFO
      message = "EZID #{request_name} -- #{response.status_line}"
      logger.log(log_level, message)
      raise response.exception if response.exception
      response      
    end

    def execute(request_class, *args)
      response = request_class.execute(self, *args)
      handle_response(response, request_class.short_name)
    end

  end
end
