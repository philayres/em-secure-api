module SecureApi
  class ClientSecret

    attr_accessor :secret

    @cached_secrets = {}

    def self.create client, options={}       
      res = find client

      if res 
        if options[:replace_client]
          delete client
        else          
          raise "Client already exists and :replace_client option not specified"
        end    
      end

      key = generate_secret client    
      Database.query("INSERT INTO clients (name, shared_secret, client_type, created_at) values ('#{Database.escape(client)}', '#{Database.escape(key)}', 1, '#{DbConnection.at_value}')")
      puts "INSERT INTO clients "
      cached_secrets.delete(client)    
      key
    end

    def self.delete client
      cached_secrets.delete(client)

      Database.query("DELETE FROM clients WHERE  name = '#{Database.escape(client)}'")            
    end

    def self.find client
      return nil if client.nil? || client.empty?
      c = nil #cached_secrets[client]
      return c if c

      c = ClientSecret.new      
      results = Database.query("SELECT shared_secret FROM clients WHERE name='#{Database.escape(client)}' LIMIT 1")    
      return nil unless results.count == 1
      puts "Database find client (#{client}) received #{results.count}: #{results.first.inspect}"
      c.secret = results.first['shared_secret']      
      #cached_secrets[client] = c
      c
    end

  private
    def self.cached_secrets
      @cached_secrets
    end

    def self.generate_secret key
      Digest::SHA256.hexdigest("client:#{key}...generated at:#{Time.new}...with random number #{rand(10**52)}")
    end
  end
end