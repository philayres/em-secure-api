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
    
    def self.generate_uri params, action, controller, options={}
      params[:timestamp] = Time.new.strftime('%s%3N') unless params[:timestamp]

      secret = get_secret options, params
      
      generate_ottoken params, secret, action, controller, options

      options[:call_string]
    end

    def self.generate_form params, action, controller, options={}
      params[:timestamp] = Time.new.strftime('%s%3N') unless params[:timestamp]

      secret = get_secret options, params
      
      ottoken = generate_ottoken params, secret, action, controller, options

      params[:ottoken] = ottoken
      return params
    end
    
    def self.generate_ottoken params, secret, action, controller, options={}

      uri_set = []
      uri_set_esc = []
      sign_params = params.to_a 
      sign_params.sort! {|x,y| x <=> y }

      sign_params.each do |k,v|
        pname = k.to_s        
        # Use a subset of character substitutions for URI encoding
        pval = v.to_s.gsub('%', '%25').gsub('&', '%26').gsub('=', '%3D').gsub('?', '%3F')
        uri_set << "#{pname}=#{pval}"
        uri_set_esc << "#{pname}=#{CGI.escape pval}"
      end

      uri_string = "#{secret}/#{controller}/#{action}?#{uri_set.join('&')}"    
      options[:uri_string] = uri_string # Allow testing of the result
      ottoken = Digest::SHA256.hexdigest(uri_string)
      call_string = "/#{controller}/#{action}?#{uri_set_esc.join('&')}&ottoken=#{ottoken}"    
      options[:call_string] = call_string
      ottoken
    end
  
  protected

    def self.get_secret options, params
      if options[:secret]
        options[:secret]
      else
        ClientSecret.find(params[:client]).secret
      end      
    end


  end
end
