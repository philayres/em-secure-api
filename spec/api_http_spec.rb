require 'rspec'
$testing = true
#require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib em_server]))
REQ = File.expand_path('./lib')
require "#{REQ}/em_server"
require "#{REQ}/secure_api/api_auth"

$baseurl = 'localhost'
$port = Port
$server = "http://#{$baseurl}:#{$port}"

UID = "test_user#{rand(1000000000)}@test.repse.com"
UID2 = "specialtester#{rand(1000000000)}@test.repse.com"

require './lib/client/requester'

describe '/admin#status' do
  before(:all) do        
    test_client = 'test_admin'
    secret = SecureApi::ClientSecret.create(test_client, :replace_client=>true)       
    @requester = ReSvcClient::Requester.new $server, test_client, secret
  end
  
  it "should check status of server - if it fails, ensure the server is running" do        
    params = {}
    path = '/admin/status'      
    @requester.make_request :get, params, path
    @requester.code.should == SecureApi::Response::OK   
  end
  
  
  
end

describe '/identities' do
  before(:all) do
    
    # clear up first
    test_client = 'test_client'
    secret = SecureApi::ClientSecret.create(test_client, :replace_client=>true)
    @requester = ReSvcClient::Requester.new $server, test_client, secret
  end
  
  it "should check status of server - if it fails, ensure the server is running" do    
    params = {}
    path = '/admin/status'
    @requester.make_request :get, params, path
    @requester.code.should == SecureApi::Response::OK   
  end
  
  it "should create a user identity " do    
    params = {user_id: UID, email: UID, name_first: "testfn", name_last: "testln", org: 'test co', dept: 'finance', city: 'Boston', state: 'Massachusetts', country: 'US'}
    path = '/identities/create'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    puts @requester.body    
  end

  it "should find a user identity " do    
    params = {user_id: UID}
    path = '/identities/find'
    @requester.make_request :get, params, path
    @requester.code.should == SecureApi::Response::OK
    puts JSON.parse @requester.body
  end  
  
  it "should update a user identity " do    
    params = {user_id: UID, email: "new_#{UID}", name_last: 'newln'}
    path = '/identities/update'
    Log.info "TESTING UPDATE"
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    
    Log.info "RESULT FROM TEST: #{j}"
    
    j['email'].should == "new_#{UID}"
    j['name_last'].should == 'newln'        
    j['name_first'].should == 'testfn'
    
  end  

  it "should find a user identity again" do    
    params = {user_id: UID}
    path = '/identities/find'
    @requester.make_request :get, params, path
    @requester.code.should == SecureApi::Response::OK
    puts JSON.parse @requester.body
  end  
  
  it "should generate keys" do    
    params = {user_id: UID, password: 'test password!'}
    path = '/identities/generate_keys'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    
    #j['public_key'].should_not be_nil
   
  end   
  
  it "should s/mime some data" do
    data = "This is some data.\nThis should be a nice signed document."
    subject = 'Signed document 1'
    params = {user_id: UID, password: 'test password!', data: data, subject: subject, mime: 'text/plain'}
    path = '/content/smime_data'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    j['smime'].should_not be_nil
    puts j['smime']
    
    File.write '/tmp/smime-1.p7m',j['smime']
  end  
  
  it "should return a certificate" do
    params = {user_id: UID}
    path = '/identities/certificate'
    @requester.make_request :get, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    j['certificate'].should_not be_nil
    
    
    File.write '/tmp/cert-out1.pem',j['certificate']
  end
  
  it "should regenerate keys" do    
    params = {user_id: UID, password: 'test password!'}
    path = '/identities/generate_keys'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
       
  end     
  
  
  
  it "should s/mime some data with regenerated keys" do
    data = "This is some data.\nThis should be a nice signed document."
    subject = 'Signed document 2'
    params = {user_id: UID, password: 'test password!', data: data, subject: subject, mime: 'text/plain'}
    path = '/content/smime_data'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    j['smime'].should_not be_nil
    puts j['smime']
    
    File.write '/tmp/smime-2.p7m',j['smime']
  end
  
  it "should s/mime some more data with regenerated keys" do
    data = "This is some more different data.\nThis should be a nice signed document."
    subject = 'Signed document 2A'
    params = {user_id: UID, password: 'test password!', data: data, subject: subject, mime: 'text/plain'}
    path = '/content/smime_data'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    j['smime'].should_not be_nil
    puts j['smime']
    
    File.write '/tmp/smime-2a.p7m',j['smime']
  end  

  it "should create a new user identity " do    
    params = {user_id: UID2, email: UID2, name_first: "bob", name_last: "smith", org: 'testme co', dept: 'IT', city: 'Providence', state: 'Rhode Island', country: 'US'}
    path = '/identities/create'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    puts @requester.body    
  end  

  it "should generate new keys" do    
    params = {user_id: UID2, password: 'secret password!'}
    path = '/identities/generate_keys'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body       
  end       

  it "should s/mime some HTML data" do
    data = "<h2>This is some data.</h2><p>This should be a nice signed document.</p><p>Looks good, right?</p>"
    subject = 'Signed html document'
    params = {user_id: UID2, password: 'secret password!', data: data, subject: subject, mime: 'text/html'}
    path = '/content/smime_data'
    @requester.make_request :post, params, path
    @requester.code.should == SecureApi::Response::OK
    j =  JSON.parse @requester.body
    j['smime'].should_not be_nil
    puts j['smime']
    
    File.write '/tmp/smime-3.p7m',j['smime']
  end  
  
  it "should sign a PDF document" do
    data = File.open("./testfiles/terms_agreement.pdf",  encoding: 'utf-8')
    subject = 'Signed PDF document'
    params = {user_id: UID2, password: 'secret password!', reason: subject, x_pos: "69.0", y_pos: "300.5", page: '7' }
    path = '/content/sign_pdf'
    
    @requester.make_request :post, params, path, nil, optional_params: {file: data}
    @requester.code.should == SecureApi::Response::OK
    j =  @requester.body
    puts j
    
    tempfile = Tempfile.new ['test', '.pdf']
    res = tempfile.write j  #, encoding: 'utf-8'
    tf = tempfile.path
    puts j
    puts tf
    `evince #{tf}`
  end  
end

