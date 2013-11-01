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
    
    # Check correct creation of an ottoken string with character encodings
    t = Time.new.strftime('%s%3N')
    params = {b: 123, c: 'abc', adg: 'hello phil', rand: 'this & this = a question?', timestamp: t, client: test_client}
    ot = SecureApi::ApiAuth.generate_ottoken(params, secret, 'do', 'some_controller', res)
    expected_response = secret + '/some_controller/do?adg=hello phil&b=123&c=abc&client='+test_client+'&rand=this %26 this %3D a question%3F&timestamp=' + t
    res[:uri_string].should == expected_response
    
    # Check result is repeatable
    ot2 = SecureApi::ApiAuth.generate_ottoken(params, secret, 'do', 'some_controller', res)
    ot.should == ot2
    
    # Check a timelag produces a different ottoken result
    sleep(0.1)
    t2 = Time.new.strftime('%s%3N')
    params[:timestamp] = t2    
    ot_test = SecureApi::ApiAuth.generate_ottoken(params, secret, 'do', 'some_controller', res)
    puts res[:uri_string]
    puts ot_test    
    res[:uri_string].should_not == expected_response
    
    # Check timeout allows some lag before rejecting the timeout
    sleep(1.0)
    params[:ottoken] = ot_test
    otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'do', 'some_controller', res)
    puts res[:uri_string]
    otres.should == true

    # Check changed action breaks validation
    expect { otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'done', 'some_controller', res) }.to raise_error
    

    # Check unknown client prevents access
    params[:client]='test_clien'
    ot_test = SecureApi::ApiAuth.generate_ottoken(params, secret, 'do', 'some_controller', res)    
    expect { otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'do', 'some_controller', res)  }.to raise_error
    
    
    # Check ottoken timeout with very short max timeout (100ms)
    res[:max_timeout]=100    
    expect {otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'do', 'some_controller', res) }.to raise_error

    # Now test adding the client
    secret = SecureApi::ClientSecret.create('test_clien')
    res = {}
    params = {b: 123, c: 'abc', adg: 'hello phil', rand: 'this & this = a question?', timestamp: t, client: 'test_clien'}
    params[:ottoken] = SecureApi::ApiAuth.generate_ottoken(params, secret, 'do', 'some_controller', res)    
    
    # Test finding the new client secret and validating
    secret = SecureApi::ClientSecret.find('test_clien').secret    
    otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'do', 'some_controller', res) 
    
    # Now check for one time only validation
    otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'do', 'some_controller', one_time_only: true) 
    
    expect {otres = SecureApi::ApiAuth.validate_ottoken(params, secret, 'do', 'some_controller', one_time_only: true) }.to raise_error
    
    SecureApi::ClientSecret.delete('test_clien')    
  end
  

end

