require "#{REQ}/secure_api/api_auth_gen.rb"
module SecureApi
  class ApiAuth

    def self.validate_ottoken params, secret, action, controller, options={}

      ottoken = params[:ottoken]
      timestamp = params[:timestamp]

      throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Incorrect parameters in validate_ottoken"} unless ottoken && timestamp && !ottoken.empty?

      timedout =  (timestamp.to_i - current_timestamp.to_i).abs > max_time_difference(controller, action, options)
      throw :not_authorized_request, {:status=>Response::TOKEN_TIMEOUT, :content_type=>Response::TEXT ,:content=>"Request has timed out"} if timedout

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

    #Timeout in milliseconds
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