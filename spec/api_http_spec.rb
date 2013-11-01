$baseurl = 'localhost'
$port = Port
require 'net/http'

describe '/admin#status' do
  before(:all) do    
    # clear up first
    $test_client = 'test_admin'
    SecureApi::ClientSecret.create($test_client, :replace_client=>true)    
  end
  
  it "should check status of server - if it fails, ensure the server is running" do    
    params = {client: $test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'status', 'admin')
    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.code.to_i.should == SecureApi::Response::OK   
  end
end

describe '/controller1' do
  before(:all) do
    
    # clear up first
    $test_client = 'test_client'
    SecureApi::ClientSecret.create($test_client, :replace_client=>true)
  end
  
  it "should check status of server - if it fails, ensure the server is running" do    
    params = {client: $test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'status', 'admin')
    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.code.to_i.should == SecureApi::Response::OK   
  end
  
  it "should exercise controller1 successfully" do    
    test_client = $test_client

    opt = {}
    
    params = {username: 'phil', password: 'hello phil', opt1: 'this', client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action1', 'controller1', opt)
        

    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.body.should == "{\"opt1\":\"THIS\",\"opt2\":null}"
    response.code.to_i.should == SecureApi::Response::OK
        
    # Check for reused ottoken
    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.body.should == "ottoken already used"
    response.code.to_i.should == SecureApi::Response::CONFLICT

    # Check for old ottoken
    response = Net::HTTP.get_response($baseurl, '/controller1/action1?client=test_client&username=phil&password=abc&opt1=nnn&timestamp=234234&ottoken=23423443', $port)
    response.body.should == "Request has timed out"
    response.code.to_i.should == SecureApi::Response::NOT_AUTHORIZED
    
    # Check for reused overridden password in the route definition
    params = {username: 'phil', opt1: 'this', opt2: 'that', client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action2', 'controller1', opt)
    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.body.should == "{\"opt1\":\"this\",\"opt2\":\"that\",\"pw\":null}"
    response.code.to_i.should == SecureApi::Response::OK
    
    # Check for reused overridden password in the route definition
    params = {username: 'phil', opt1: 'this', opt2: 'that', client: test_client, password: 'hey there'}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action2', 'controller1', opt)
    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.body.should == "{\"opt1\":\"this\",\"opt2\":\"that\",\"pw\":\"hey there\"}"
    response.code.to_i.should == SecureApi::Response::OK

    
    # Check action not found
    params = {username: 'phil', opt1: 'this', opt2: 'that', client: test_client, password: 'hey there'}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action2a', 'controller1', opt)
    response = Net::HTTP.get_response($baseurl, uri, $port)    
    response.code.to_i.should == SecureApi::Response::NOT_FOUND
  end


  it "should exercise controller2 successfully" do    
    test_client = $test_client

    opt = {}
    
    # Test action2 processes correctly with its before and after handlers
    params = {username: 'phil', password: 'hello phil', opt1: 'this', opt2: 'more',client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action2', 'controller2', opt)        
    response = Net::HTTP.get_response($baseurl, uri, $port)
    response.body.should == "{\"opt1\":\"this\",\"opt2\":\"more\",\"username\":\"phil\"}"
    response.code.to_i.should == SecureApi::Response::OK

    # Test before filter
    params = {username: 'bob', opt1: 'this', opt2: 'more',client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action2', 'controller2', opt)
        
    response = Net::HTTP.get_response($baseurl, uri, $port)    
    response.code.to_i.should == SecureApi::Response::NOT_FOUND

    # Test after filter
    params = {username: 'phil', password: 'not secret', opt1: 'this', opt2: 'more',client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'action2', 'controller2', opt)
        
    response = Net::HTTP.get_response($baseurl, uri, $port)    
    response.code.to_i.should == SecureApi::Response::BAD_REQUEST
    
    # Post posting a request
    params = {username: 'phil', password: 'hello phil', opt1: 'this', opt2: 'more', opt3: 'go for it',client: test_client}
    post_form_params = SecureApi::ApiAuth.generate_form(params, 'action1', 'controller2', opt)
    uri = URI("http://#{$baseurl}:#{$port}/controller2/action1")
    response = Net::HTTP.post_form(uri, post_form_params)
    response.body.should == "{\"posted\":\"POSTED!\",\"opt1\":\"this\",\"opt2\":\"more\",\"opt3\":\"go for it\"}"
    response.code.to_i.should == SecureApi::Response::OK
  end

  it "should test timeouts " do    
    test_client = $test_client

    opt = {}
    
    # Test status
    params = {client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'status', 'admin', opt)        
    response = Net::HTTP.get_response($baseurl, uri, $port)    
    response.code.to_i.should == SecureApi::Response::OK
    
    # Test status with sleep in it
    params = {client: test_client}
    uri = SecureApi::ApiAuth.generate_uri(params, 'status', 'admin', opt)        
    sleep 6
    response = Net::HTTP.get_response($baseurl, uri, $port)        
    puts response.code, response.body
    response.code.to_i.should == SecureApi::Response::TOKEN_TIMEOUT 
  end
end

