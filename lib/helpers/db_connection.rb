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
  
  def self.transaction(&block)
    raise ArgumentError, "No block was given" unless block_given?
    
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
      DBP[:pool].with do |db|      
        res = db.query query
        lid = db.last_id
        Log.debug "Query: #{res} && #{lid} for SQL:\n#{query}"
        res = lid if !res && lid #&& lid!=0
        options[:last_id] = lid
        return res
      end
    rescue Mysql2::Error => e
      return handle_mysql_error e
    end
  
  end
  
  def self.handle_mysql_error e
    if e.sql_state.to_s=='closed MySQL connection' || e.sql_state.to_s == 'MySQL server has gone away'                         
      Log.info "SQL Connection was closed. Restarting"
      DBP[:pool].shutdown rescue nil
      DBP[:pool] = create_new_pool
      return nil
    else
      Log.info "SQL Connection error unknown: #{e.error_number} / #{e.sql_state} == #{e.inspect}"
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