require 'rspec'
$testing = true

REQ = File.expand_path('./lib')
#require "#{REQ}/em_server"

require './lib/api_models/data_encryption'
require './lib/api_models/electronic_signature'
require './lib/api_models/user_identity'
require 'base64'

describe ElectronicSignature do

  it "should generate p7s" do      

    user_identity = UserIdentity.new 'phil.ayres@repse.com'
  
    user_identity.name_first = 'Phil'
    user_identity.name_last = 'Ayres'
    user_identity.representing_org_dept = 'CTO'
    user_identity.representing_org = 'REPSE Inc'
    user_identity.address_city = 'Quincy'
    user_identity.address_state = 'MA'
    user_identity.address_country = 'USA'
    user_identity.email_address = 'phil.ayres@repse.com'
    
    pw = 'TestPassword!'
    
    res = ElectronicSignature.generate_keys user_identity, pw
    
    cert = ElectronicSignature.generate_user_certificate(user_identity, pw, :secure=>:pkcs12, :password=>pw) 
    
    File.write "/tmp/phil.pkcs12", cert
  end
  
  it "should generate user keys" do
  
    pw = 'testpw'
  
    user_identity = UserIdentity.new 'testuser123'
  
    user_identity.name_first = 'Phil'
    user_identity.name_last = 'Smith'
    user_identity.representing_org_dept = 'CEO'
    user_identity.representing_org = 'Test LLC'
    user_identity.address_city = 'Quincy'
    user_identity.address_state = 'MA'
    user_identity.address_country = 'USA'
    user_identity.email_address = 'phil.smith@test.consected.com'

  
    res = ElectronicSignature.generate_keys user_identity, pw
    
    res2 = user_identity.get_private_key_pem pw
    res2.index('-----BEGIN RSA PRIVATE KEY-----').should == 0
  
  
    # Sign a document
    
    text = "This is a really important contract.\nDated: #{DateTime.now.to_s}"
    
    #text = File.read '/home/phil/Downloads/PDFReference16.pdf'
    
    
    data = text
    digest = OpenSSL::Digest::SHA256.new
    #pkey = user_identity.get_private_key pw #OpenSSL::PKey::RSA.new(2048)
    #signature = pkey.sign(digest, data)
    signature = ElectronicSignature.sign_data text, user_identity, pw
    #puts signature
    pub_key = user_identity.get_public_key
    pub_key.verify(digest, signature, data).should be_true
        
        
    
    
    pkcs7 = ElectronicSignature.sign_data_pkcs7 text, user_identity, pw, :detached  
    
    File.write '/tmp/pkcs7.pem', pkcs7
    File.write '/tmp/pkcs7text', text
    
    
    
    sig = ElectronicSignature.sign_data text, user_identity, pw  
    File.write '/tmp/pkcs7.sig', sig
    
    pkcs7 = ElectronicSignature.sign_data_pkcs7 text, user_identity, pw
    
    File.write '/tmp/pkcs7emb.pem', pkcs7
    
    
    pkcs7 = ElectronicSignature.sign_data_pkcs7 text, user_identity, pw, :detached
    
    File.write '/tmp/pkcs7emb.der', pkcs7.to_der
    
    
    smime_data = ElectronicSignature.smime_data text, user_identity, pw, "Signed request", 'text/plain'
    File.write '/tmp/pkcs7.p7m', smime_data
    
    #signature = ElectronicSignature.generate_checksum pkcs7
    
    #puts signature
    
    #rescheck = ElectronicSignature.validate_signature smime_data, pkcs7.to_pem, user_identity    
    #rescheck.should be_true    
    

    
  end
  
end
