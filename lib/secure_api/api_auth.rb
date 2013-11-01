module SecureApi
  class ApiAuth

    def self.generate_uri params, action, controller, options={}
      params[:timestamp] = Time.new.strftime('%s%3N') unless params[:timestamp]

      secret = ClientSecret.find(params[:client]).secret
      generate_ottoken params, secret, action, controller, options

      options[:call_string]
    end

    def self.generate_form params, action, controller, options={}
      params[:timestamp] = Time.new.strftime('%s%3N') unless params[:timestamp]

      secret = ClientSecret.find(params[:client]).secret
      
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

    def self.validate_ottoken params, secret, action, controller, options={}

      ottoken = params[:ottoken]
      timestamp = params[:timestamp]

      throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Incorrect parameters in validate_ottoken"} unless ottoken && timestamp && !ottoken.empty?

      timedout =  (timestamp.to_i - current_timestamp.to_i).abs > max_time_difference(options)
      throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Request has timed out"} if timedout

      sign_params = params.dup
      sign_params.delete(:ottoken)



      otgen = generate_ottoken(sign_params, secret, action, controller, options)
      throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"ottoken does not match"} unless (otgen == ottoken)    

      if options[:one_time_only]
        throw :not_authorized_request, {:status=>Response::CONFLICT, :content_type=>Response::TEXT ,:content=>"ottoken already used"} if exists?(ottoken)
      end

      if options[:one_time_only] || options[:log_request]
        params[:ottoken] = ottoken
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

    def self.log_requests(params)
      Database.query("INSERT INTO request_log (ottoken, action, controller, client, created_at) values (
          '#{Database.escape(params[:ottoken])}', 
          '#{Database.escape(params[:action])}', 
          #{params[:controller] ? "'#{Database.escape(params[:controller])}'" : NULL}, 
          '#{Database.escape(params[:client])}', '#{DbConnection.at_value}')"
        )
    end

  private    
    def self.current_timestamp
      Time.new.strftime('%s%3N')
    end

    def self.max_time_difference options={}
      #Timeout in milliseconds
      options[:max_timeout] || 30000    
    end

  end
end