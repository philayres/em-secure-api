require 'rubygems'
require 'json'
require 'digest/sha2'
require 'httpclient'

module ReSvcClient

  class Requester
    
    AUTH_HEADER_NAME = 'X-Nonce'

    attr_accessor :server, :client, :shared_secret
    
    def initialize server, client, shared_secret
      @server = server
      @client = client
      @shared_secret = shared_secret
    end
    
    def millisec_timestamp
      (Time.now.to_f * 1000).to_i
    end

    def generate_auth_header method, params, path, options={}
      timestamp = options[:force_timestamp] || millisec_timestamp
      ottoken = generate_header_ottoken method, params, path, timestamp
      {AUTH_HEADER_NAME => "#{ottoken} #{client} #{timestamp}"}        
    end

    def generate_header_ottoken method, params, path, timestamp
      content = params.collect {|k,v| "#{k}=#{CGI.escape v.to_s}"}.join('&')
      method_new = method.to_s.upcase
      Digest::SHA256.hexdigest("#{method_new}#{path}#{content}#{client}#{shared_secret}#{timestamp.to_s}")
    end
    
    def cleanup
      @result = nil
      @json_result = nil
    end
    
    def make_request method, params, action, controller=nil, options={}
      
      cleanup
      path = ""    
      
      if action.include?("/") && !controller 
        path = action
      else
        path << "/#{controller}"  if controller && !controller.empty?
        path << "/#{action}"      
      end
      
      header = generate_auth_header method, params, path, options
      
      httpmethod = method.downcase.to_sym      
      url = "#{server}#{path}"
            
      res = httpclient.send(httpmethod, url, params, header)
      @result = res            
      if res && res.body && !res.body.empty?
        @json_result = JSON.parse(res.body) rescue nil
      else
        @json_result = nil
      end
      
      res
    end
    
    def body
      @result.body
    end
    
    def code
      @result.code
    end
    
    def data 
      @json_result
    end
    
    def httpclient
      @httpclient ||= HTTPClient.new
    end
    
  end
  
  
end
