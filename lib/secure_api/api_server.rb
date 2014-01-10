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
      return @headers if @headers
      res = @http_headers.split("\0")
      hs = {}
      res.each do |h|
        hv = h.split(': ',2)
        hs[hv[0]] = hv[1] unless hv[0].nil?
      end
      @headers = hs      
    end

    def post_content
      @http_post_content
    end
    
    def content_type
      @http_content_type
    end
    
    def content_length
      l = headers['content-length'].to_i
      puts "CONTENT LENGTH: #{l}"
      l
    end
    
    FORM_DATA_MEDIA_TYPES = [
      #'application/x-www-form-urlencoded',
      'multipart/form-data'
    ]
    
    PARSEABLE_DATA_MEDIA_TYPES = [
      'multipart/related',
      'multipart/mixed'
    ]
    
    def media_type
      content_type && content_type.split(/\s*[;,]\s*/, 2).first.downcase
    end    
    
    def form_data?
      type = media_type      
      (method == :post && type.nil?) || FORM_DATA_MEDIA_TYPES.include?(type)
    end

    
    def parseable_data?
      PARSEABLE_DATA_MEDIA_TYPES.include?(media_type)
    end        
    
    def params              
      return @request_params if @request_params      
      from_string = ''
      @request_params = {} 
      puts @http_post_content
      
      if method==:post || method==:put 
        if form_data? || parseable_data?           
          io = StringIO.new(@http_post_content, 'rb')          
          io.rewind
          @multipart = SecureApi::Multipart.new content_type, io, content_length
          from_string << @http_query_string if @http_query_string
                    
          @multipart.parse
          
        else        
          # Just a simple POSTED form passed
          from_string << @http_query_string if @http_query_string
          from_string << @http_post_content if @http_post_content
        end
      else  
        # Just use the GET params
        from_string << @http_query_string if @http_query_string
      
      end
      
      
      if @multipart && @multipart.params
        @request_params.merge!(@multipart.params)
      end
      
      if from_string.empty?
        
        return {}
      end
      
      if from_string.length > ::ParamLengthLimit
        KeepBusy::log_and_raise "Parameters too long"
      end

      param_list = from_string.split('&')
      
      @request_params = {}
      param_list.each do |p|
        pp = p.split('=',2)        
        @request_params[pp[0].to_sym] = CGI.unescape(pp[1] || '') if pp[0] && !pp[0].empty?
      end

      
      @request_params
    end   

    def authorize_request

      #secret_obj = ClientSecret.find(params[:client])
      #throw :not_authorized_request, {:status=>Response::NOT_AUTHORIZED, :content_type=>Response::TEXT ,:content=>"Client not recognized"} unless secret_obj
      #secret = secret_obj.secret
      if defined?(CONFIG_USE_NONCE_PARAM) && CONFIG_USE_NONCE_PARAM && params[CONFIG_USE_NONCE_PARAM]
        pb = Base64.decode64(params[CONFIG_USE_NONCE_PARAM])
        p = JSON.parse(pb)
        headers[ApiAuth::AUTH_HEADER_NAME] = p[ApiAuth::AUTH_HEADER_NAME]
        Log.info  "Using #{CONFIG_USE_NONCE_PARAM} parameter rather than header: #{p}"
        params.delete(CONFIG_USE_NONCE_PARAM)
      end
      
      check_params = params
      
      if defined?(CONFIG_AUTH_PARAMS) && CONFIG_AUTH_PARAMS
        check_params = params.select {|k,v| CONFIG_AUTH_PARAMS.include?(k)}
      end
      
      ApiAuth.validate_ottoken(method, headers, check_params, action, controller, :one_time_only=>AllowOneTimeOnly, :method=>method)        
    end
    
    def send_response res, response
      res[:content] = res[:content].to_json if res[:content_type]==Response::JSON && res[:content]
      response.status = res[:status]
      response.content_type res[:content_type]
      response.content = res[:content]
      #response.send_response
    end



      def process_http_request

          resp = EM::DelegatedHttpResponse.new(self)
          # Use deferred responses, to handle the blocking calls within separate threads
          
          work  = proc do
            begin                              

              params  
          
          
    #        puts "New request: #{@http_request_method} #{@http_request_uri} #{@http_query_string} #{@http_post_content}"        
              res = catch :request_exit do
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
              end



              Log.info "Response: #{res[:status]} #{res[:content_type]} #{(res[:content] || '').to_s[0..1000]}"
              send_response res, resp    

            rescue => e
              if e.is_a?(String)
                Log.warn "Bad request: #{e.inspect}"
                resp.status = 401
                resp.content_type 'text/plain'
                resp.content = "Bad request: #{e.inspect}"
                #resp.send_response
              else

                Log.warn "Error processing request: #{e.inspect}\n#{e.backtrace.join("\n")}"
                resp.status = 500
                resp.content_type 'text/plain'
                resp.content = "Internal error: #{e.inspect}"
                #resp.send_response
              end
            
            end
                        
          end
          
        callback = proc do
          resp.send_response
        end
        
        EM.defer work, callback
    end
  end

end
