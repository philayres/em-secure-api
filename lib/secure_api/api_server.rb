module SecureApi
  class ApiServer < EM::Connection
    
    include EM::HttpServer
      
    def self.start_serving port, options=nil
      
      options ||= {}
      
      EM.run{
        msg = " Start em-server-api with Ruby version #{RUBY_VERSION} on port #{port} as pid #{$$}\n"
        puts DateTime.now.to_s + msg
        KeepBusy.logger.info msg
        
        EM.threadpool_size = options[:threads] if options[:threads]
        
        EM.start_server '127.0.0.1', port, SecureApi::ApiServer
        puts DateTime.now.to_s + " Started em-server-api\n"
      }

    end
    
    def post_init
        super
        no_environment_strings
       
       # max length of the POST content
       self.max_content_length = 100_000_000       
       
      puts "Content length max = #{self.max_content_length}"
      
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
      l = headers['Content-Length'].to_i     
      l
    end
    
    FORM_DATA_MEDIA_TYPES = [
      
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
      @url_params = {}
      @body_params = {}

      if method==:post || method==:put 
        if form_data? || parseable_data?      
          
          io = StringIO.new(@http_post_content, 'rb')          
          io.rewind
          @multipart = SecureApi::Multipart.new content_type, io, content_length
          from_string << @http_query_string if @http_query_string
                    
          @multipart.parse
      #mulpart are all body params
          if @multipart && @multipart.params
            @request_params.merge!(@multipart.params)
            @body_params = @multipart.params
          end
      @url_params = @http_query_string
        else 
          @url_params = http_content_query_parse(@http_query_string, from_string)       
          @body_params = http_content_query_parse(@http_post_content, from_string)
        end
      else  
        @url_params = http_content_query_parse(@http_query_string, from_string)
      end
      if from_string.empty?
        return {}
      end
      
      if from_string.length > ::ParamLengthLimit
        KeepBusy::log_and_raise "Parameters too long"
      end
      @request_params = @url_params.merge(@body_params)
   
    end

    def http_content_query_parse http_content, from_string
      request_params_content = {}
      if http_content 
        from_string << http_content 
        param_list = http_content.split('&')
        param_list.each do |p|
          pp = p.split('=', 2)
          request_params_content[pp[0].to_sym] = CGI.unescape(pp[1] || '') if pp[0] && !pp[0].empty?
        end
      end
      request_params_content
    end

    def authorize_request


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
      
      content = res[:content]
      content.force_encoding(Encoding::ASCII_8BIT) if content
      response.content = content
    end



    def process_http_request

          resp = EM::DelegatedHttpResponse.new(self)
          # Use deferred responses, to handle the blocking calls within separate threads
          
          success_result = nil
          api = nil
          
          work  = proc do
            begin                              

              params  
          
          
    #        puts "New request: #{@http_request_method} #{@http_request_uri} #{@http_query_string} #{@http_post_content}"        
              res = catch :request_exit do
                res = catch :not_initialized do
                  api = Api.new controller, action, method, params, @body_params, @url_params, resp

                  res = catch :not_authorized_request do
                    authorize_request


                    api.before_handler
                    res = catch :not_processed_request do
                      res = api.do_request
                    end

                    api.after_handler
                    puts api
                    res
                  end

                end
              end



              Log.info "Response: #{res[:status]} #{res[:content_type]} #{(res[:content] || '').to_s[0..1000]}"
              send_response res, resp    
              success_result = res

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
          ac = Api.action_callback controller, action, method
          if ac
            res = ac.call success_result, resp, self
          else
            resp.send_response
        
          end

        end

        EM.defer work, callback
    end
  end

end
