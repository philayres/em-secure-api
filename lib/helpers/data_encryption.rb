require 'openssl'

class DataEncryption
  
  def self.ivsalt
    "akjsdf89ujomcerfk^%$^Tuiyhhiunyhn904[[[[^!231n40c9cn2umio~%^78yniuinioh987x342193"
  end
#  def self.generate_dn entity
#    
#    entity.each do |k,v|
#      entity[k] = Net::LDAP::DN.escape(v)
#    end
#    
#    OpenSSL::X509::Name.parse("/UID=#{entity[:uid]}/CN=#{entity[:common_name]}/OU=#{entity[:department]}/O=#{entity[:organization]}/L=#{entity[:city]}/ST=#{entity[:state]}/C=#{entity[:country]}")
#  end


  def self.encrypt_data data, objkey, salt,  extras={}
    raise "No data provided to encrypt" if data.nil? || data.empty?
    raise "No object key provided" if objkey.nil? || objkey.empty?
    raise "No object key salt provided" if salt.nil? || salt.empty?

    data = data.dup
    objkey = objkey.dup
    salt = salt.dup
    
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')    
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(objkey, salt, 20000, 256)
    iv = OpenSSL::Digest::SHA256.digest(objkey << ivsalt)     
    
    cipher.encrypt
    cipher.key = key    
    cipher.iv = iv
    result = cipher.update(data)
    result << cipher.final
    if extras[:base64_data]==true
      Base64.encode64(result)
    else
      result
    end
  end

  def self.unencrypt_data data, objkey, salt,  extras={}    
    raise "No data provided to encrypt" if data.nil? || data.empty?
    raise "No object key provided" if objkey.nil? || objkey.empty?
    raise "No object key salt provided" if salt.nil? || salt.empty?

      data = data.dup
      objkey = objkey.dup
      salt = salt.dup
    
    if extras[:base64_data]==true
      data = Base64.decode64(data)
    end
    return '' if data.empty?
    begin
      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(objkey, salt, 20000, 256)
      iv = OpenSSL::Digest::SHA256.digest(objkey << ivsalt)     
      
      cipher.decrypt
      cipher.key = key    
      cipher.iv = iv
      result2 = cipher.update( data )
      result2 << cipher.final
      result2  
    rescue => e      
      raise "ERROR: Failure in unobscure_data: Data is: #{data[0..100]}\n #{e.inspect} "
    end
  end  


end
