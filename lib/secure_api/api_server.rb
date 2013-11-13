module SecureApi
  class ApiServer < EM::Connection
    
    include EM::HttpServer
      
        # the http request details are available via the following instance variables:
        #   @http_protocol
        #   @http_request_method
        #   @http_cookie
        #   @http_if_none_match
        #   @http_content_type
        #   @http_path_info
        #   @http_request_uri
        #   @http_query_string
        #   @http_post_content
        #   @http_headers

    def self.start_serving port
      
      EM.run{
        puts DateTime.now.to_s + " Start em-server-api with Ruby version #{RUBY_VERSION} on port #{port}\n"
        EM.start_server '127.0.0.1', port, SecureApi::ApiServer
        puts DateTime.now.to_s + " Started em-server-api\n"
      }

    end
    
    def post_init
        super
        no_environment_strings
    end
      
    def controller
      @http_request_uri.split('/').select{|s| s && !s.empty?}[0..-2].join('/')
    end
      
    def action
      @http_request_uri.split('/').select{|s| s  && !s.empty?}.last
    end
      
    def method
      @http_request_method.downcase.to_sym
    end
    
    def headers
      
      res = @http_headers.split("\0")
      hs = {}
      res.each do |h|
        hv = h.split(': ',2)
        hs[hv[0]] = hv[1] unless hv[0].nil?
      end
      hs
    end

    def params              
      return @request_params if @request_params      
      from_string = ''
      from_string << @http_query_string if @http_query_string
      from_string << @http_post_content if @http_post_content
      if from_string.empty?
        @request_params = {} 
        return {}
      end

      param_list = from_string.split('&')
      # Sorting the param list allows for correct operation of the parameter signature calculation

      @request_params = {}
      param_list.each do |p|
        pp = p.split('=',2)        
        @request_params[pp[0].to_sym] = CGI.unescape(pp[1] || '') 
      end

      @request_params
    end   

    def authorize_request

      #secret_obj = ClientSecret.find(params[:client])
      #throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Client not recognized"} unless secret_obj
      #secret = secret_obj.secret
            
      ApiAuth.validate_ottoken(method, headers, params, action, controller, :one_time_only=>true, :method=>method)        
    end
    
    def send_response res
      res[:content] = res[:content].to_json if res[:content_type]==Response::JSON && res[:content]
      response.status = res[:status]
      response.content_type res[:content_type]
      response.content = res[:content]
      response.send_response
    end

    def response
      @response
    end

      def process_http_request

        
#        puts "New request: #{@http_request_method} #{@http_request_uri} #{@http_query_string} #{@http_post_content}"
        params
        begin
          
          @response = EM::DelegatedHttpResponse.new(self)

          
          res = catch :not_initialized do
            api = Api.new controller, action, method, params

            res = catch :not_authorized_request do
              authorize_request


              api.before_handler
              res = catch :not_processed_request do
                res = api.do_request
              end

              api.after_handler

              res
            end
            
          end
          
          send_response res        

        rescue => e
          if e.is_a?(String)
            Log.warn "Bad request: #{e.inspect}"
            response.status = 401
            response.content_type 'text/plain'
            response.content = "Bad request: #{e.inspect}"
            response.send_response
          else

            Log.warn "Error processing request: #{e.inspect}\n#{e.backtrace.join("\n")}"
            response.status = 500
            response.content_type 'text/plain'
            response.content = "Internal error: #{e.inspect}"
            response.send_response
          end
        end
    end
  end

end
