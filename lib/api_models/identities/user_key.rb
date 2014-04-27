module Identities
  class UserKey < DbObject
    
    
    BinaryTag = '>>>BINARY::'
    
    def self.table_name 
      'user_keys'
    end

    def table_name 
      self.class.table_name
    end
    
    no_serialize([:private_key])
    attr_accessor :id, :user_id, :user_uid, :user_key_id, :private_key, :public_key, :certificate, :serial, :created_at, :active_until

    def self.find_current user_uid
      
      condition = "user_uid = '#{user_uid}'"
      
      sql = "SELECT * from #{table_name} INNER JOIN active_user_keys ON active_user_keys.user_key_id=#{table_name}.id WHERE #{condition}"
      get_record sql
    end
        
    def initialize user_id=nil, user_uid=nil, private_key_encrypted_b64=nil, public_key=nil, certificate=nil
      return unless user_id
      @user_id = user_id
      @user_uid = user_uid
      @private_key = private_key_encrypted_b64
      @public_key = public_key
      @certificate = certificate
      @id = nil
    end
        
    
    def private_key_binary      
      res = Base64.decode64(@private_key)
      Log.info "Getting pke binary #{res}"
      res
    end
    
    
    def save 
      
      uk = UserKey.find_current(@user_uid)      
      unless uk
        Log.info "No existing key record: #{uk} for (#{@user_uid})"
        res = Database.transaction do |db|
          sql = "INSERT INTO #{table_name} (user_id, user_uid, private_key, public_key, certificate, created_at)
            values (#{@user_id}, '#{@user_uid}', '#{Database.escape private_key}', '#{Database.escape @public_key}',
            '#{Database.escape @certificate}', '#{Database.at_value}')"
          resid = db.query sql
          @id = db.last_id
          Log.info "Created key record with ID: #{@id}"
          sql = "INSERT INTO active_#{table_name} (user_key_id, created_at)
            values ('#{@id}', '#{Database.at_value}')"
          Log.info "Attempting to activate record: #{sql}"
          db.query sql
        end
      else    
        Log.info "Found existing key record: #{uk.user_key_id} for (#{@user_uid})"
        ukid = uk.user_key_id
        res = Database.transaction do |db|
          sql = "UPDATE #{table_name} SET                     
            active_until = '#{Database.at_value}' WHERE id = #{ukid}"
          Log.info "SQL: #{sql}"
          db.query sql          
          Log.info "Deactivated key record with ID: #{ukid}"
          sql = "INSERT INTO #{table_name} (user_id, user_uid, private_key, public_key, certificate)
            values (#{@user_id}, '#{@user_uid}', '#{Database.escape private_key}', '#{Database.escape @public_key}',
            '#{Database.escape @certificate}')"
          Log.info "SQL: #{sql}"
          resid = db.query sql          
          Log.info "Created key record with ID: #{db.last_id}"
          sql = "UPDATE active_#{table_name} SET user_key_id = '#{db.last_id}' WHERE user_key_id = #{ukid}"          
          Log.info "Attempting to activate new record: #{sql}"
          Log.info "SQL: #{sql}"
          db.query sql          
        end
      end
      
      
      Log.info "Failed SQL\n#{res}" unless res      
      res
    end
    
  private
    def save_sql
    end
    
  end
end
