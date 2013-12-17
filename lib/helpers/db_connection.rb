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

    
    
    def self.create_new_pool
      ConnectionPool.new(size: 10, timeout: 5) { connect(::Config[:database]) }
  end
  
  end
  
  def self.query query
    begin
      DBP[:pool].with do |db|      
        return db.query query
      end
    rescue Mysql2::Error => e
      if e=='closed MySQL connection'
        Log.info "SQL Connection was closed. Restarting"
        DBP[:pool].shutdown rescue nil
        DBP[:pool] = create_new_pool
        return nil
      else
        Log.info "SQL Connection error unknown: #{e.inspect}"
        return nil
      end
    end
  
  end
  
  def self.escape str
    Mysql2::Client.escape str
  end

  def self.at_value
    Time.new.to_s
  end  
end