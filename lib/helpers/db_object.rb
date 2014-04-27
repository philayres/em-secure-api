class DbObject

  def self.no_serialize vars
    @no_serialize = vars
  end

  def self.get_record sql
    res = Database.query sql      

    if res && res.count > 0  
      res = res.first
      res = hash_to_object res        
      Log.debug "Got record: #{res.uid} " if res.respond_to? :uid
      Log.debug "Got record: #{res.id} " if res.respond_to? :id
      return res
    else
      Log.debug "No record found for : #{sql}"
      return nil
    end
    nil
  end
  
  def self.find_by condition
            
    sql = "SELECT * from #{table_name} where #{condition}"      
    return get_record sql
  end

  def self.hash_to_object h
    obj = new 
    h.each do |k,v|
      obj.send("#{k}=".to_sym, v) # unless k.to_sym == :uid || k.to_sym == :id
    end      
    obj.is_new = false
    
    Log.info "Hash for (#{obj.id}) is: #{h.inspect}"
    
    obj
  end

  def save 
    Log.debug "Save #{is_new ? 'new' : 'existing'} record #{@uid} or #{@id}"      
    options={}
    res = Database.query save_sql, options
    if res
      @id = options[:last_id] if options[:last_id] && is_new
      @is_new = false
    else
      Log.info "Failed SQL: #{save_sql}\n#{res}"      
    end
    res
  end

  def is_new
    @is_new
  end

  def is_new= val
    @is_new = val
  end

  def to_json j=nil
    res = {}
    instance_variables.each do |k| 
      s = k.to_s.gsub('@','')
      res[s] = instance_variable_get(k) unless no_serialize(s)
    end
    res.to_json
  end
  
  def no_serialize s
    return nil unless s
    ns = self.class.get_no_serialize
    return nil unless ns
    ns.include?(s.to_sym)      
  end
  
  def self.get_no_serialize 
    @no_serialize
  end
  
  

end
