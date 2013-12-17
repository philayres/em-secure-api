require "#{REQ}/secure_api/api_auth_gen.rb"
module SecureApi
  class ApiAuth

    def self.validate_ottoken method, headers, params, action, controller, options={}

      method = method.to_s.upcase      
      nonce = headers[AUTH_HEADER_NAME]

      unless nonce && method 
        throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Method or nonce not provided"}
      end
      
      ottoken, client, timestamp = nonce.split(' ', 3)

      unless ottoken && timestamp && client 
        throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Incorrect parameters in validate_ottoken"}
      end
      
      
      ctest = SecureApi::ClientSecret.find(client)      
      unless ctest
        throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"client not known"}
      end  
      
      secret = options[:secret] || ctest.secret # Allow override      
      timestamp = timestamp.to_i
      
      timedout =  (timestamp - millisec_timestamp).abs > max_time_difference(controller, action, options)
      throw :not_authorized_request, {:status=>Response::TOKEN_TIMEOUT, :content_type=>Response::TEXT ,:content=>"Request has timed out"} if timedout

      sign_params = params.dup

      options[:force_timestamp] = timestamp
      otgen = generate_auth_header_for_action(method, sign_params, client, secret, action, controller, options)
      otgenval = otgen.first.last
            
     
      unless (otgenval == nonce)          
        
        KeepBusy.logger.info "Details: #{method}, #{headers.inspect}, #{params.inspect}, #{action}, #{controller}, #{options.inspect}====#{otgenval}!=#{nonce}"
        
        throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"ottoken does not match"} 
      end

      if options[:one_time_only]
        throw :not_authorized_request, {:status=>Response::CONFLICT, :content_type=>Response::TEXT ,:content=>"ottoken already used"} if exists?(nonce)
      end


      
      if options[:one_time_only] || options[:log_request]
        params[:client] = client
        params[:ottoken] = nonce
        params[:action] = action
        params[:controller] = controller
        log_requests(params)
      end

      return true
    end

    def self.exists?(ottoken)
      results = Database.query("SELECT ottoken FROM request_log WHERE ottoken='#{Database.escape(ottoken)}' LIMIT 1")
      return (results.count > 0)
    end

    # Log requests
    # Must be performed synchronously within the request, since one-time checking relies on this
    def self.log_requests(params)
      Database.query("INSERT INTO request_log (ottoken, action, controller, client, created_at) values (
          '#{Database.escape(params[:ottoken])}', 
          '#{Database.escape(params[:action])}', 
          #{params[:controller] ? "'#{Database.escape(params[:controller])}'" : NULL}, 
          '#{Database.escape(params[:client])}', '#{Database.at_value}')"
        )
    end

  private    

    # Timeout in milliseconds
    def self.max_time_difference controller, action, options={}
      
      # Step through most specific to least
      if ::RequestTimeout[controller.to_sym]
        to_action = ::RequestTimeout[controller.to_sym]["#{action}_#{options[:method]}".to_sym] 
        to_controller = ::RequestTimeout[controller.to_sym][:__default]
      end
      to_default = ::RequestTimeout[:__default]
      
      mto = options[:max_timeout] || to_action || to_controller || to_default
      
      mto
    end

  end
end