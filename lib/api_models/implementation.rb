# A test implementation to allow api_http_spec tests to run and exercise the API
# It also should make a good skeleton from which to create real implementations

require 'net/http'

module SecureApi
  
  class Implementation < SecureApi::ApiControl    
    
    def routes
      {
        identities: {
          __default_parameters: {user_id: :req, uid: :opt},
          create_post: {params: {name_first: :req, name_last: :req, org: :req, dept: :req, city: :req, state: :req, country: :req, email: :req, private_digest: :opt } },
          update_post: {params: {name_first: :opt, name_last: :opt, org: :opt, dept: :opt, city: :opt, state: :opt, country: :opt, email: :opt } },
          find_get: {params: {user_id: :opt, uid: :opt, email: :opt} },
          generate_keys_post: {params: {password: :req } },
          certificate_get: {params: {}}
        },
        content: {
          smime_data_post: {params: {user_id: :req, password: :req, data: :req, mime_type: :opt, subject: :req } }
        },
        admin: {
          status_get: {}
        }
      }
    end

    def bad_request?
      false
    end

    def set_identity_params params
      @user_identity.name_first = params[:name_first] if params[:name_first]
      @user_identity.name_last = params[:name_last] if params[:name_last]
      @user_identity.dept = params[:dept] if params[:dept]
      @user_identity.org = params[:org] if params[:org]
      @user_identity.city = params[:city] if params[:city]
      @user_identity.state = params[:state] if params[:state]
      @user_identity.country = params[:country] if params[:country]
      @user_identity.email = params[:email] if params[:email]
    end
    
    def find_by_conditions      
      conditions = {user_id: params[:user_id]} if params[:user_id]
      conditions = {uid: params[:uid]} if params[:uid]
      
      return conditions
    end
    
    def identities_create_post
      @user_identity = Identities::UserIdentity.new params[:user_id]
      set_identity_params params
      
      if @user_identity.save
        res = {uid: @user_identity.uid} 
        
        if params[:private_digest]          
          res_cert = @user_identity.generate_keys params[:private_digest]
          Log.info "Identities create also requested to generate keys. #{res_cert.inspect}"
        end
        
        set_response  status: Response::OK , content_type: Response::JSON, content: res
      else
        set_response  status: 401, content_type: Response::JSON, content: {error: 'Failed to save user identity'}
      end
      
    end

    def identities_update_post
      
      Log.info "Finding:::: #{find_by_conditions.inspect}"
      @user_identity = Identities::UserIdentity.find_by find_by_conditions
      Log.info "Found:::: #{@user_identity.inspect}"
      unless @user_identity
        set_response  status: Response::NOT_FOUND , content_type: Response::JSON, content: {}
        return
      end
      
      set_identity_params params
      Log.info "Updated params::::: #{@user_identity}"
      res  = @user_identity.save
      
      Log.info "RES:::: #{res}"
      
      if res        
        res =  @user_identity
        set_response  status: Response::OK , content_type: Response::JSON, content: res
      else
        set_response  status: 401, content_type: Response::JSON, content: {error: 'Failed to save user identity'}
      end
      
    end

    def identities_find_get
      
      @user_identity = Identities::UserIdentity.find_by find_by_conditions
      Log.info "GOT find: #{@user_identity.inspect}"
      
      if @user_identity
        set_response  status: Response::OK , content_type: Response::JSON, content: @user_identity
      else
        set_response  status: Response::NOT_FOUND , content_type: Response::JSON, content: {}
      end
    end
    
    def identities_certificate_get
      
      @user_identity = Identities::UserIdentity.find_by find_by_conditions
      
      
      if @user_identity
        cert = @user_identity.get_certificate chain: true
        set_response  status: Response::OK , content_type: Response::JSON, content: {certificate: cert}
      else
        set_response  status: Response::NOT_FOUND , content_type: Response::JSON, content: {}
      end
    end    
    
    def identities_generate_keys_post
      @user_identity = Identities::UserIdentity.find_by find_by_conditions                
      
      Log.info "GOT generate: #{@user_identity.inspect}"
      if @user_identity
        res = @user_identity.generate_keys params[:password]
        set_response  status: Response::OK , content_type: Response::JSON, content: {public_key_id: res }
      else
        set_response  status: Response::NOT_FOUND , content_type: Response::JSON, content: {}
      end
      
    end
    
    
    def content_smime_data_post
      @user_identity = Identities::UserIdentity.find_by find_by_conditions
      
      if @user_identity
        mime = params[:mime_type] if params[:mime_type] && !params[:mime_type].empty?
        mime ||= 'text/html'
        
        res = Identities::ElectronicSignature.smime_data params[:data], @user_identity, params[:password], params[:subject], mime
        set_response  status: Response::OK , content_type: Response::JSON, content: {smime: res }
      else
        set_response  status: Response::NOT_FOUND , content_type: Response::JSON, content: {}
      end
      
            
    end



    def admin_status_get
      set_response status: Response::OK, content_type: Response::JSON, content: {} 
    end

    
  end
end