DEBUG = true
require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'digest/sha2'
require 'mysql2'
require 'json'
require 'date'
require 'base64'
require 'cgi'
require 'date'
require 'json'
require 'connection_pool'
Dir[File.dirname('./initializers') + '/*.rb'].each {|file| require file }
require "#{REQ}/secure_api/response"
require "#{REQ}/secure_api/api_server"
require "#{REQ}/helpers/logging.rb"
require "#{REQ}/helpers/config_manager.rb"
require "#{REQ}/helpers/db_connection.rb"
require "#{REQ}/secure_api/client_secret"
require "#{REQ}/secure_api/api_auth"
require "#{REQ}/secure_api/api_control"
require "#{REQ}/api_models/implementation"


Config = ConfigManager.get_config
BaseDirs = Config[:directories]
Log = Logger.start_logging('log')
Api = SecureApi::Implementation
Port = $force_port || Config[:server][:port]
RequestTimeout = Config[:server][:request_timeout] || {__default: 30000}

DBP = ConnectionPool.new(:size => 10, :timeout => 5) { Database::DbConnection.connect(::Config[:database]) }

SecureApi::ApiServer.start_serving Port unless $testing || $configuration