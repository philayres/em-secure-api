## A test implementation to allow api_http_spec tests to run and exercise the API
# It also should make a good skeleton from which to create real implementations

require 'net/http'
module SecureApi
  
  class Implementation < SecureApi::ApiControl    
    
    def routes
      {
        controller1: {
          __default_parameters: {username: :req, password: :req},
          action1_get: {params: {opt1: :req, opt2: :opt } },
          action2_get: {params: {opt1: :req, opt2: :req, password: :opt } },
          action3_get: {params: {opt1: :req, password: :exc } },
          actionmissing_get: {params: {opt1: :req, password: :exc } }      
        },
        controller2: {
          action1_post: {params: {opt1: :req, opt2: :opt, opt3: :req } },
          action2_get: {params: {opt1: :req, opt2: :req } },      
          action3_get: {params: {} },
          action3_post: {},
          action4_post: {params: {opt1: :req, opt2: :opt, opt3: :req } },
          action5_post: {params: {}},
          action6_post: {params: {}}
          
        },
        admin: {
          status_get: {}
        }
      }
    end

    def bad_request?
      false
    end

    def controller1_action1_get
      opt1 = params[:opt1].upcase
      opt2 = "#{params[:opt2].upcase} has been forced to upper case" if params[:opt2]
      set_response  status: Response::OK , content_type: Response::JSON, content: {opt1: opt1, opt2: opt2} 
    end

    def controller1_action2_get
      set_response  status: Response::OK , content_type: Response::JSON, content: {opt1: params[:opt1], opt2: params[:opt2], pw: params[:password]} 
    end

    def controller1_action3_get

    end

    def controller2_action1_post
      set_response  status: Response::OK , content_type: Response::JSON, content: {posted: "POSTED!", opt1: params[:opt1], opt2: params[:opt2], opt3: params[:opt3]} 
    end

    def controller2_action2_get
      set_response  status: Response::OK , content_type: Response::JSON, content: {opt1: params[:opt1], opt2: params[:opt2], username: params[:username]} 
    end

    def controller2_action3_get

    end

    def controller2_action3_post

    end

    def controller2_action4_post
      set_response  status: Response::OK , content_type: Response::JSON, content: {posted: "POSTED!", opt1: params[:opt1], opt2: params[:opt2], opt3: params[:opt3]} 
    end

    def controller2_action5_post
      KeepBusy.logger.info params.inspect 
      set_response  status: Response::OK , content_type: Response::JSON, content: {url_params: @url_params , body_params: @body_params } 
    end

    def controller2_action6_post
      KeepBusy.logger.info params.inspect 
      set_response status: Response::BAD_REQUEST , content_type: Response::JSON, content: {ok: "it is not"}
    end
    
    # An example of a callback method definition for the appropriate controller, action, method 
    # Notice that this is prefixed with self. since it is initially referenced against the class
    # not an instance of the object.
    # Note that it is the responsibility of the callback to call response.send_response in order to mark the end of
    # the HTTP request
    # The arguments passed in provide control:
    #   result: the original set_response hash as set by the 
    #           controller_action_method implementation
    #   request: the ApiServer instance that was instantiated during the call
    #           which can be used to access the original params hash
    
    def self.callback_controller2_action6_post result, response, request
      puts "Using alternative callback for #{result} "      
      # Notice the usage: api.set_response ... since we are not inside the Api instance when this method is initially used
      # We can also use the original `result` from the action implementation (for example, result[:content_type])      
      res = {status: Response::OK, content_type: result[:content_type], content: {ok: "it is#{request.params[:a_value]}"} }
      sleep 1
      # Repeat this to override previous settings
      request.send_response res, response
      response.send_response
    end

    def admin_status_get
      set_response status: Response::OK, content_type: Response::JSON, content: {} 
    end

    def before_controller2_get
      if params[:username] == ''
        throw :not_processed_request, {status: Response::NOT_FOUND, content_type: Response::TEXT , content: "no such record"}
      end      
    end

    def after_controller2_all
      if params[:password] == ''        
        throw :request_exit, {status: Response::BAD_REQUEST, content_type: Response::TEXT, content: 'This password is not secret.'}
      end      
    end
    
  end
end
