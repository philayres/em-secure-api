$baseurl = 'localhost'
$port = Port
$server = "http://#{$baseurl}:#{$port}"

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

describe '/controller1' do
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
  
  it "should check for a tampered request " do    
    params = {}
    # Adding a parameter in the URL acts the same as 'tampering' with the request, since
    # the path is not used to calculate the sent ottoken header in make_request
    path = '/admin/status?invalid_to_include=123'
    @requester.make_request :get, params, path
    @requester.code.should == SecureApi::Response::NOT_AUTHORIZED
    @requester.body.should == 'ottoken does not match'
        
  end
  
  
  it "should exercise controller1 successfully" do    
    
    params = {username: 'phil', password: 'hello phil', opt1: 'this'}
    
    path = '/controller1/action1'
    options = {}
    options[:force_timestamp] = @requester.millisec_timestamp    
    
    @requester.make_request :get, params, path, nil, options
    @requester.code.should == SecureApi::Response::OK      
    @requester.body.should == "{\"opt1\":\"THIS\",\"opt2\":null}"
    @requester.data['opt1'].should == 'THIS'
        
    # Check for reused ottoken
    @requester.make_request :get, params, path, nil, options    
    @requester.body.should == "ottoken already used"
    @requester.code.should == SecureApi::Response::CONFLICT

    # Check for old ottoken

    options[:force_timestamp] = @requester.millisec_timestamp - 100000
    @requester.make_request :get, params, path, nil, options    
    @requester.body.should == "Request has timed out"
    @requester.code.should == SecureApi::Response::NOT_AUTHORIZED
    
    # Check for reused overridden password in the route definition
    path = '/controller1/action2'
    params = {username: 'phil', opt1: 'this', opt2: 'that'}
    
    @requester.make_request :get, params, path, nil
    @requester.body.should == "{\"opt1\":\"this\",\"opt2\":\"that\",\"pw\":null}"
    @requester.code.should == SecureApi::Response::OK
        
    # Check for reused overridden password in the route definition
    params = {username: 'phil', opt1: 'this', opt2: 'that', password: 'hey there'}
    @requester.make_request :get, params, path, nil
    @requester.body.should == "{\"opt1\":\"this\",\"opt2\":\"that\",\"pw\":\"hey there\"}"
    @requester.code.should == SecureApi::Response::OK

    
    # Check action not found
    path = '/controller1/action2a'
    params = {username: 'phil', opt1: 'this', opt2: 'that', password: 'hey there'}
    @requester.make_request :get, params, path, nil    
    @requester.code.should == SecureApi::Response::NOT_FOUND
  end

end

describe '/controller2' do
  before(:all) do
    
    # clear up first
    test_client = 'test_client'
    secret = SecureApi::ClientSecret.create(test_client, :replace_client=>true)
    @requester = ReSvcClient::Requester.new $server, test_client, secret
  end
#joshs test
  it "action 2 before filter should fail without persons username controller2" do    
     opt = {}
    
     # Test action2 processes correctly with its before and after handlers
     path = '/controller2/action2'
     params = {username: '', opt1: 'this', opt2: 'more'}     
     @requester.make_request :get, params, path, nil    
     @requester.code.should == SecureApi::Response::NOT_FOUND

   end
  it "action 2 after filter should fail without  persons password controller2" do    
     opt = {}
    
     # Test action2 processes correctly with its before and after handlers
     path = '/controller2/action2'
     params = {username: 'phil', password: '', opt1: 'this', opt2: 'more'}
     @requester.make_request :get, params, path, nil    
     @requester.code.should == SecureApi::Response::BAD_REQUEST

  end
 it "action 1 should post upon a successful login" do 
    opt = {}
    
    params = {username: 'phil', password: 'hello phil', opt1: 'this', opt2: 'more', opt3: 'go for it'}
    path = '/controller2/action1'    
    @requester.make_request :post, params, path, nil    
    @requester.body.should == "{\"posted\":\"POSTED!\",\"opt1\":\"this\",\"opt2\":\"more\",\"opt3\":\"go for it\"}"
    @requester.code.should == SecureApi::Response::OK
  end

  it "action 4 should post upon a successful login" do 
    opt = {}
    
    params = {username: 'phil', password: 'hello phil', opt1: 'this', opt2: 'more', opt3: 'go for it'}
    path = '/controller2/action4'    
    @requester.make_request :post, params, path, nil    
    @requester.body.should == "{\"posted\":\"POSTED!\",\"opt1\":\"this\",\"opt2\":\"more\",\"opt3\":\"go for it\"}"
    @requester.code.should == SecureApi::Response::OK
  end

#other new test
  it "action 5 should take a required param and not fail without the optional params" do
    opt = {}

    params = {username: 'any', password: 'anything', abc_params: 'blah', def_params: 'like'}
    path = '/controller2/action5'
    @requester.make_request :post, params, path, nil
    @requester.body.should == "{\"url_params\":{},\"body_params\":{\"username\":\"any\",\"password\":\"anything\",\"abc_params\":\"blah\",\"def_params\":\"like\"}}"
    @requester.code.should == SecureApi::Response::OK
  end

#josh test end

  it "action 6 should test an alternative callback" do
    opt = {}

    params = {username: 'any', password: 'anything'}
    path = '/controller2/action6'
    @requester.make_request :post, params, path, nil
    @requester.body.should == "{\"ok\":\"it is\"}"
    @requester.code.should == SecureApi::Response::OK
  end

  it "action 6 should test an alternative callback again" do
    opt = {}

    params = {username: 'any', password: 'anything', a_value: " a good callback"}
    path = '/controller2/action6'
    @requester.make_request :post, params, path, nil
    @requester.body.should == "{\"ok\":\"it is a good callback\"}"
    @requester.code.should == SecureApi::Response::OK
  end
  
  it "action 6 should test an alternative callback is reset cleanly" do
    opt = {}

    params = {username: 'any', password: 'anything'}
    path = '/controller2/action6'
    @requester.make_request :post, params, path, nil
    @requester.body.should == "{\"ok\":\"it is\"}"
    @requester.code.should == SecureApi::Response::OK
  end
    
  it "should test timeouts " do    
    path = '/admin/status'
    options = {}
    options[:force_timestamp] = @requester.millisec_timestamp    
    params = {}
    
    @requester.make_request :get, params, path, nil, options    
    @requester.code.should == SecureApi::Response::OK
    
    # Test status with sleep in it    
    sleep 6
    @requester.make_request :get, params, path, nil, options    
    @requester.code.should == SecureApi::Response::TOKEN_TIMEOUT 
    
    
    @requester.make_request :get, params, path, nil
    @requester.code.should == SecureApi::Response::OK 
  end
end
