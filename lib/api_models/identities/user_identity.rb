module Identities
  class UserIdentity < DbObject
        
    
    attr_accessor :id, :uid, :user_id,
     :name_first, :name_last, :dept, :org, 
     :city, :state, :country, :email, :created_at, :updated_at

    
    
    def self.table_name 
      'user_identities'
    end

    def table_name 
      self.class.table_name
    end

    
    def initialize user_id=nil
      return unless user_id
      @user_id = user_id
      @uid = Digest::MD5.hexdigest user_id
      @is_new = true
            
    end
    
    
    def self.find_by options
      
      if options[:id]
        condition = "id = #{Database.escape options[:id]}"
      elsif options[:user_id]
        condition = "user_id = '#{Database.escape options[:user_id]}'"
      elsif options[:uid]
        condition = "uid = '#{Database.escape options[:uid]}'"
      elsif options[:email]
        condition = "email = '#{Database.escape options[:email]}'"        
      end
      
      return super(condition)
    end

    def generate_keys password
            
      secure_private_key, public_key, private_key = ElectronicSignature.generate_keys self, password                                    
      certificate = ElectronicSignature.generate_user_certificate private_key, public_key, generate_dn
      
      spk64 = Base64.encode64(secure_private_key)
      
      Log.info "Saving newly generated keys with #{@id}, #{@uid} for #{@user_id}"
      uk = UserKey.new @id, @uid, spk64, public_key, certificate  
      uk.save
      
      
      unless get_private_key(password).is_a?(OpenSSL::PKey::RSA)
        raise "Primary key generate check failed "
      end
      
      uk
    end
    
    def current_user_keys
      uk = UserKey.find_current @uid
    end
    
    def get_certificate options={}
      res = current_user_keys.certificate
      res = "#{res}#{ElectronicSignature::CA_CERT_PEM}" if options[:chain]
      return OpenSSL::X509::Certificate.new(res)if options[:x509]
      res
    end
    
    def get_root_certificate options={}
      res = ElectronicSignature::CA_CERT_PEM
      return OpenSSL::X509::Certificate.new(res)if options[:x509]
      res
    end
    
    def get_private_key_pem password
      DataEncryption.unencrypt_data current_user_keys.private_key_binary, @user_id, ElectronicSignature.mangle_password(password)
    end

    def get_public_key
      OpenSSL::PKey::RSA.new(current_user_keys.public_key)
    end

    def get_private_key password
      OpenSSL::PKey::RSA.new get_private_key_pem(password)
    end
    
    def generate_dn 
      user = self
      dn = []
      dn << ['UID', user.user_id]
      dn << ['CN', "#{user.name_first} #{user.name_last}"]
      dn << ['OU', user.dept]
      dn << ['O', user.org]
      dn << ['L', user.city]
      dn << ['ST', user.state]
      dn << ['C', user.country]
      dn << ['emailAddress', user.email]
      OpenSSL::X509::Name.new dn
    end

    
  private

    def save_sql
      if is_new
        sql = "INSERT INTO #{table_name} (uid, user_id, name_first, name_last, dept, org, 
          city, state, country, email, created_at) values ('#{uid}', '#{Database.escape user_id}', '#{Database.escape name_first}',
          '#{Database.escape name_last}', '#{Database.escape dept}', '#{Database.escape org}', 
          '#{Database.escape city}', '#{Database.escape state}', '#{Database.escape country}',
          '#{Database.escape email}', '#{Database.at_value}')"
      else
        sql = "UPDATE #{table_name} SET 
          uid = '#{Database.escape uid}',
          user_id = '#{Database.escape user_id}',
          name_first = '#{Database.escape name_first}',
          name_last = '#{Database.escape name_last}', 
          dept = '#{Database.escape dept}', 
          org = '#{Database.escape org}', 
          city = '#{Database.escape city}',
          state = '#{Database.escape state}', 
          country = '#{Database.escape country}', 
          email = '#{Database.escape email}', 
          updated_at = '#{Database.at_value}' WHERE id = '#{id}'"
      end
      return sql
    end
    
  
  end
end