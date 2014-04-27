#
# Notes:
# To get Adobe Reader to recognize your signatures, the repse.cer file must be added to the trusted certificates
# Go to Document / Manage Trusted Identities
# Click Add Contacts button
# Browse for repse.cer
# REPSE Inc Signing should appear in the top panel
# Click Import button
# In the certificates list that appears, select REPSE Inc Signing
# Click Edit Trust...
# Check the box Use this certificate as a trusted root
# Click OK
# Click Close on the certificate list window
# Now you can open your PDF file
#


require 'rspec'
$testing = true

REQ = File.expand_path('./lib')
#require "#{REQ}/em_server"
KB_BASE_DIR = File.expand_path('.')


require './lib/environment'
#require './lib/helpers/logging'
#require './lib/helpers/db_object'
#require './lib/helpers/data_encryption'
#require './lib/api_models/identities/electronic_signature'
#require './lib/api_models/identities/user_identity'
#require 'base64'

describe 'ElectronicSignature' do

#  it "should generate p7s" do      
#
#    user_identity = Identities::UserIdentity.new 'phil.ayres@repse.com'
#  
#    user_identity.name_first = 'Phil'
#    user_identity.name_last = 'Ayres'
#    user_identity.dept = 'CTO'
#    user_identity.org = 'REPSE Inc'
#    user_identity.city = 'Quincy'
#    user_identity.state = 'MA'
#    user_identity.country = 'USA'
#    user_identity.email = 'phil.ayres@repse.com'
#    
#    user_identity.save.should be_true
#    
#    pw = 'TestPassword!'
#    
#    res = user_identity.generate_keys pw
#    
#    #cert = Identities::ElectronicSignature.generate_user_certificate(user_identity, pw, :secure=>:pkcs12, :password=>pw) 
#    cert = user_identity.get_certificate chain: true
#    File.write "/tmp/phil.pkcs12", cert
#  end
#  
#
#  
#  it "should generate user keys" do
#  
#    pw = 'testpw'
#  
#    user_identity = Identities::UserIdentity.new 'testuser123'
#  
#    user_identity.name_first = 'Phil'
#    user_identity.name_last = 'Smith'
#    user_identity.dept = 'CEO'
#    user_identity.org = 'Test LLC'
#    user_identity.city = 'Quincy'
#    user_identity.state = 'MA'
#    user_identity.country = 'USA'
#    user_identity.email = 'phil.smith@test.consected.com'
#
#    user_identity.save.should be_true
#  
#    res = user_identity.generate_keys pw
#    
#    res2 = user_identity.get_private_key_pem pw
#    res2.index('-----BEGIN RSA PRIVATE KEY-----').should == 0
#  
#  
#    # Sign a document
#    
#    text = "This is a really important contract.\nDated: #{DateTime.now.to_s}"
#    
#    #text = File.read '/home/phil/Downloads/PDFReference16.pdf'
#    
#    
#    data = text
#    digest = OpenSSL::Digest::SHA256.new
#    #pkey = user_identity.get_private_key pw #OpenSSL::PKey::RSA.new(2048)
#    #signature = pkey.sign(digest, data)
#    signature = Identities::ElectronicSignature.sign_data text, user_identity, pw
#    #puts signature
#    pub_key = user_identity.get_public_key
#    pub_key.verify(digest, signature, data).should be_true
#        
#        
#    
#    
#    pkcs7 = Identities::ElectronicSignature.sign_data_pkcs7 text, user_identity, pw, :detached  
#    
#    File.write '/tmp/pkcs7.pem', pkcs7
#    File.write '/tmp/pkcs7text', text
#    
#    
#    
#    sig = Identities::ElectronicSignature.sign_data text, user_identity, pw  
#    File.write '/tmp/pkcs7.sig', sig
#    
#    pkcs7 = Identities::ElectronicSignature.sign_data_pkcs7 text, user_identity, pw
#    
#    File.write '/tmp/pkcs7emb.pem', pkcs7
#    
#    
#    pkcs7 = Identities::ElectronicSignature.sign_data_pkcs7 text, user_identity, pw, :detached
#    
#    File.write '/tmp/pkcs7emb.der', pkcs7.to_der
#    
#    
#    smime_data = Identities::ElectronicSignature.smime_data text, user_identity, pw, "Signed request", 'text/plain'
#    File.write '/tmp/pkcs7.p7m', smime_data
#
#
#    
#  end
#  
  
  it "should run PDF signature" do


    user_identity = Identities::UserIdentity.new 'phil.ayres@repse.com'
  
    user_identity.name_first = 'Phil'
    user_identity.name_last = 'Ayres'
    user_identity.dept = 'CTO'
    user_identity.org = 'REPSE Inc'
    user_identity.city = 'Quincy'
    user_identity.state = 'MA'
    user_identity.country = 'USA'
    user_identity.email = 'phil.ayres@repse.com'
    
    user_identity.save.should be_true
    
    pw = 'TestPassword!'
    
    res = user_identity.generate_keys pw    
    
    
    #INPUTFILE = "./testfiles/Sample.pdf"
    INPUTFILE = './testfiles/newpdf2.pdf'
    SIGIMG = './testfiles/repse-text-logo-b.jpg'
    @inputfile = String.new(INPUTFILE)
    OUTPUTFILE = @inputfile.insert(INPUTFILE.rindex("."),"_signed")    
    
    Prawn::Document.generate(INPUTFILE) do
      text "Hello World!"
    end
    


    spd = SignPDF.new user_identity, pw    
    spd.in_filename = INPUTFILE
    spd.out_filename = OUTPUTFILE
    
    spd.sign page: 1, x_pos: 69.0, y_pos: 200.0
   
  end  
  
end
