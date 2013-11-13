require 'rspec'
$testing = true
#require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib em_server]))
REQ = File.expand_path('./lib')
require "#{REQ}/environment"
require "#{REQ}/secure_api/api_auth"


describe SecureApi::ApiAuth do
  before(:each) do
    @api_auth = SecureApi::ApiAuth.new
  end

  
  it "should get the secret for the client from the database" do
    SecureApi::ClientSecret.create('test_clien', :replace_client=>true)
    expect {SecureApi::ClientSecret.create('test_clien')}.to raise_error
    SecureApi::ClientSecret.delete('test_clien')
    
    secret = SecureApi::ClientSecret.create('test_client', :replace_client=>true)
    res = SecureApi::ClientSecret.find('test_client')        
    res.secret.should == secret
    
    res = SecureApi::ClientSecret.find('test_clien')    
    res.should == nil
    
    res = SecureApi::ClientSecret.find('test_client')        
    res.secret.should == secret
    
  end  
  
  it "should return same one time token" do
    res = {}
    
    test_client = 'test_client'
    # clear up first
    SecureApi::ClientSecret.delete('test_clien')
    secret = SecureApi::ClientSecret.find(test_client).secret
    method = 'GET'
    
    # Check correct creation of an ottoken string with character encodings
    t = Time.new.strftime('%s%3N')
    params = {b: 123, c: 'abc', adg: 'hello phil', rand: 'this & this = a question?'}
    ot = SecureApi::ApiAuth.generate_auth_header_for_action(method, params, test_client,  secret, 'do', 'some_controller', res)    
    ot['X-Nonce'].should_not be_nil
    
    
    # Check a timelag produces a different ottoken result
    sleep(0.1)
    t2 = Time.new.strftime('%s%3N')
    opt = {force_timestamp: t2}
    ot_test = SecureApi::ApiAuth.generate_auth_header_for_action(method, params, test_client, secret, 'do', 'some_controller', opt)
    
    ot['X-Nonce'].should_not == ot_test['X-Nonce']
    
    # Check timeout allows some lag before rejecting the timeout
    sleep(1.0)
    headers = ot_test
    
    otres = SecureApi::ApiAuth.validate_ottoken(method, headers, params, 'do', 'some_controller', opt)
    otres.should == true

    # Check changed action breaks validation
    expect { otres = SecureApi::ApiAuth.validate_ottoken(method, headers, params, 'done', 'some_controller', opt) }.to raise_error
    

    # Check unknown client prevents access    
    ot_test = SecureApi::ApiAuth.generate_auth_header_for_action(method, params, 'test_clien', secret, 'do', 'some_controller', res)    
    expect { otres = SecureApi::ApiAuth.validate_ottoken(method, ot_test, params, 'do', 'some_controller', res)  }.to raise_error
    
    
    # Check ottoken timeout with very short max timeout (100ms)
    res[:max_timeout]=100    
    expect {otres = SecureApi::ApiAuth.validate_ottoken(method, ot_test, params, 'do', 'some_controller', res) }.to raise_error

    # Now test adding the client
    secret = SecureApi::ClientSecret.create('test_clien')
    res = {}
    params = {b: 123, c: 'abc', adg: 'hello phil', rand: 'this & this = a question?'}
    headers =  SecureApi::ApiAuth.generate_auth_header_for_action(method, params, 'test_clien', secret, 'do', 'some_controller', res)    
    
    # Test finding the new client secret and validating
    secret_new = SecureApi::ClientSecret.find('test_clien').secret    
    
    secret_new.should == secret
    
    otres = SecureApi::ApiAuth.validate_ottoken(method, headers, params, 'do', 'some_controller', res) 
    
    # Now check for one time only validation
    otres = SecureApi::ApiAuth.validate_ottoken(method, headers, params, 'do', 'some_controller', one_time_only: true) 
    
    expect {otres = SecureApi::ApiAuth.validate_ottoken(method, headers, params,  'do', 'some_controller', one_time_only: true) }.to raise_error
    
    SecureApi::ClientSecret.delete('test_clien')    
  end
  

end

