module SecureApi
  class ApiControl

    def initialize controller, action, method, params, body_params, url_params
      Log.info "Request: controller:#{controller} action:#{action} method:#{method}"
      Log.info "Parameters: #{params.inspect}"
      c = routes[controller.to_sym]
      throw :not_initialized, {:status=>Response::NOT_FOUND, :content_type=>Response::TEXT ,:content=>"controller (#{controller}) not found"} unless c
      a = c["#{action}_#{method}".to_sym]
      throw :not_initialized, {:status=>Response::NOT_FOUND, :content_type=>Response::TEXT ,:content=>"action_method (#{action}_#{method}) not found in controller #{controller}"} unless a

      @before_all_handler = "before_#{controller}_all".to_sym
      @before_handler = "before_#{controller}_#{method}".to_sym
      @handler = "#{controller}_#{action}_#{method}".to_sym
      @after_handler = "after_#{controller}_#{method}".to_sym
      @after_all_handler = "after_#{controller}_all".to_sym
      @controller = controller.to_sym
      @action = action.to_sym
      @method = method.to_sym
      @params = params
      @body_params = body_params
      @url_params = url_params
      @route = a      
      @model_params = c[:__default_parameters] || {}
      @model_params.merge!(a[:params]) if a[:params]
            
      @model_params.each do |k,v|
        throw :not_initialized, {:status=>Response::UNPROCESSABLE, :content_type=>Response::TEXT ,:content=>"Missing required parameter #{k}"} if v==:req && !params[k]
        throw :not_initialized, {:status=>Response::UNPROCESSABLE, :content_type=>Response::TEXT ,:content=>"Included invalid parameter #{k}"} if v==:exc && params[k]
      end
      self
    end
    
    def routes 
      {}
    end
    
    def prevent_after_handlers
      @prevent_after_handlers = false
    end
    
    def self.action_callback c, a, m
      callback_handler = "callback_#{c}_#{a}_#{m}".to_sym
      method(callback_handler) if respond_to? callback_handler
    end
    
    def do_request
      send @before_all_handler if respond_to? @before_all_handler
      send @before_handler if respond_to? @before_handler
      send @handler
      
      unless @prevent_after_handlers        
        send @after_handler if respond_to? @after_handler
        send @after_all_handler if respond_to? @after_all_handler      
      end
      
      response
    end
    
    def params
      @params
    end
    
    def bad_request?
      false
    end
    
    def before_handler
      
    end
    
    def after_handler
      
    end
    
    def set_response res
      @response = res
    end
    
    def response
      @response
    end

    
  end 
  
end
