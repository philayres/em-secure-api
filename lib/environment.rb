DEBUG = true
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
require 'rubygems'
require 'json'
require 'eventmachine'
require 'evma_httpserver'
require 'digest/sha2'
require 'mysql2'
require 'date'
require 'base64'
require 'cgi'
require 'date'
require 'connection_pool'
require 'logger'
Dir[File.dirname('./initializers') + '/*.rb'].each {|file| require file }
require "#{REQ}/secure_api/response"
require "#{REQ}/secure_api/api_server"
#require "#{REQ}/helpers/logging.rb"
require "#{REQ}/helpers/config_manager.rb"
require "#{REQ}/helpers/db_connection.rb"
require "#{REQ}/secure_api/client_secret"
require "#{REQ}/secure_api/api_auth"
require "#{REQ}/secure_api/api_control"
require "#{REQ}/api_models/implementation"


Config = ConfigManager.get_config
BaseDirs = Config[:directories]
#Log = Logger.start_logging('log1')
KB_LOG = "#{KB_BASE_DIR}/log/run.log"

module KeepBusy
    def self.logger
    LOG
  end
  
  def self.log_and_raise e
    logger.error e
    raise e
  end

  def self.log_and_exit c, e
    logger.warn "#{c}::>#{e} "
    throw :request_exit, {status: 409, content_type: 'text/json', content: {details: e,  code: c}}
  end

  LOG = Logger.new(KB_LOG)
  LOG.info "Started running (#{self}): Log file: #{KB_LOG}"
  puts "Logging to #{KB_LOG}"  

end

Log = KeepBusy.logger

Api = SecureApi::Implementation
Port = $force_port || Config[:server][:port]
RequestTimeout = Config[:server][:request_timeout] || {__default: 30000}
ParamLengthLimit = 165536

AllowOneTimeOnly = (Config[:allow_one_time_only].nil? ? true : Config[:allow_one_time_only])

DBP = {pool: Database::DbConnection.create_new_pool }

SecureApi::ApiServer.start_serving Port unless $testing || $configuration