# A test implementation to allow api_http_spec tests to run and exercise the API
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
          action5_post: {params: {abc_params: :req, def_params: :req }}
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
      set_response  status: Response::OK , content_type: Response::JSON, content: {abc_params: params[:abc_params] , def_params: params[:def_params] } 
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