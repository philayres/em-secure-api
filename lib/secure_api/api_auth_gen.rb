# Copyright (c) 2013 Phil Ayres https://github.com/philayres

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'cgi'
require 'digest/sha2'
module SecureApi
  class ApiAuth

    #AUTH_HEADER_NAME = 'Authorization'
    AUTH_HEADER_NAME = 'X-Nonce'
            
    def self.generate_auth_header_for_action method, params, client, secret, action, controller=nil, options={}
      path = generate_path(action,controller)
      generate_auth_header method, params, client, secret, path, options
    end
   
    def self.generate_auth_header method, params, client, shared_secret, path, options={}
      timestamp = options[:force_timestamp] || millisec_timestamp
      ottoken = generate_header_ottoken method, params, client, shared_secret, path, timestamp
      {AUTH_HEADER_NAME => "#{ottoken} #{client} #{timestamp}"}        
    end

    def self.generate_header_ottoken method, params, client, shared_secret, path, timestamp
      content = params.collect {|k,v| "#{k}=#{CGI.escape v.to_s}"}.join('&')
      Digest::SHA256.hexdigest("#{method}#{path}#{content}#{client}#{shared_secret}#{timestamp.to_s}")
    end
    
    def self.generate_path action, controller=nil
      path = ""    
      if action.include?("/") && !controller 
        path = action
      else
        path << "/#{controller}"  if controller && !controller.empty?
        path << "/#{action}"      
      end
    end
    
  protected

    
    def self.millisec_timestamp
      (Time.now.to_f * 1000).to_i
    end
    
  
    def self.get_secret options, params
      if options[:secret]
        options[:secret]
      else
        ClientSecret.find(params[:client]).secret
      end      
    end


  end
end
