require "#{REQ}/helpers/config_manager.rb"

module Database
  
  class DbConnection 
  
    def initialize config    
      @connection = Mysql2::Client.new(config)
    end

    def connection
      @connection
    end

    def self.connect config
      config[:cast_booleans] = true unless config.has_key?(:cast_booleans)
      DbConnection.new(config).connection
    end

  end
  
  def self.query query
    DBP.with do |db|
      db.query query
    end
  end
  
  def self.escape str
    Mysql2::Client.escape str
  end

  def self.at_value
    Time.new.to_s
  end  
end