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
      KeepBusy.logger.info "Connecting to database"      
      config[:cast_booleans] = true unless config.has_key?(:cast_booleans)
      config[:reconnect] = true unless config.has_key?(:reconnect)
      DbConnection.new(config).connection
    end
    
    
    
    def self.create_new_pool
      KeepBusy.logger.info "Creating a new pool of database connections"      
      ConnectionPool.new(size: 10, timeout: 50) { connect(::Config[:database]) }      
    end    

  end
  
   def self.transaction(&block)
    raise ArgumentError, "No block was given" unless block_given?

     #######################
     ###### TODO - the pool is being broken by returning from the middle of it
     ###### rather than letting it exit naturally
     ###### Fix this as we did for #query
     #######################
    DBP[:pool].with do |db|      
      begin
        db.query('BEGIN')
        res = yield(db)
        lid = db.last_id        
        res = lid if !res && lid #&& lid!=0
        db.query('COMMIT')        
        return res
      rescue Mysql2::Error => e
        db.query('ROLLBACK')
        return handle_mysql_error e
      end
    end
    
  end
  
  def self.query query, options={}
    begin      
      res = nil
      DBP[:pool].with do |db|      
        
        res = db.query query
        lid = db.last_id
        Log.debug "Query: #{res} && #{lid} for SQL:\n#{query}"
        res = lid if !res && lid #&& lid!=0
        options[:last_id] = lid
        
      end
      return res
    rescue Mysql2::Error => e
      return handle_mysql_error e
    end
  
  end
  
  def self.handle_mysql_error e
    if e.error_number == 2006 || e.message=='closed MySQL connection' || e.message == 'MySQL server has gone away'                        
      Log.info "SQL Connection was closed. Restarting"
      DBP[:pool].shutdown rescue nil
      DBP[:pool] = create_new_pool
      return nil
    else
      Log.info "SQL Connection error unknown: #{e.error_number} / #{e.message} == #{e.inspect}"
      return nil
    end
  end
  
  def self.escape str
    Mysql2::Client.escape str
  end

  def self.at_value
    Time.new.to_s
  end  
end