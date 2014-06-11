require 'yaml'
require 'fileutils' 
unless defined? REQ
  REQ = File.expand_path('./lib')  
end
require "#{REQ}/helpers/data_encryption.rb"
require "#{REQ}/initializers/config_manager_config.rb"
class ConfigManager
  
  
  def initialize 
    cf = File.open "#{CONFIG_FILE}", 'rb'    
    ctext = cf.read    
    
    ckeys = YAML.load_file(ConfigManager.key_filename)
        
    
    enctext = DataEncryption.unencrypt_data(ctext, ckeys[:configuration_key], CONFIG_SALT)
    cdata = YAML.load(enctext)    
    @config = cdata
    
  end  
  
  def configuration
    @config
  end
  
  def self.get_config
    @config_manager = ConfigManager.new
    @config_manager.configuration
  end
  
  def self.create_database_config enc, ad, db, un, pw, extras=nil
    
    c = {database: {encoding: enc, adapter: ad, database: db, username: un, password: pw  }}
        
    c.merge! extras if extras
    
    
    cy = c.to_yaml
    
    key = create_psuedo_random_key
    
    data  = DataEncryption.encrypt_data(cy, key, CONFIG_SALT)    
    File.open(CONFIG_FILE, 'wb').write(data)      
  end
  
  def self.create_psuedo_random_key
    r = rand(10**52).to_s
    r << timestamp_now
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(r, CONFIG_SALT[10..50], 20000, 256)        
    
    keyc = {configuration_key: key}
    
    yk = keyc.to_yaml
    
    FileUtils.mkdir CONFIG_FILE_KEYS_DIR
    f = File.open(key_filename, 'wb').write(yk)
    
    puts "
*****************************************************************************
Psuedo random key has been written to the location below. If this is RAM disk
it will be removed on reboot. 

Key File: #{key_filename}
    
*****************************************************************************
    "
    
    key
  end
  
  def self.key_filename
    "#{CONFIG_FILE_KEYS}.#{CONFIG_SVC_NAME}"
  end

  def self.timestamp_now
    Time.now.strftime('%Y%m%d%H%M%S%L')
  end  
end