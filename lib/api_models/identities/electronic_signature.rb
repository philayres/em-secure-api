
module Identities
  class ElectronicSignature

#    CA_DN = [['emailAddress', 'info@repse.com'], ['CN', 'CA'], ['OU', 'Signatures'], ['O', 'REPSE, Inc.'], ['L', 'Quincy']['ST', 'Massachusetts'], ['C', 'US'] ]

  CA_PRIVATE_KEY = OpenSSL::PKey::RSA.new <<-_end_of_pem_
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
_end_of_pem_
    
    CA_CERT_PEM = <<-_end_of_pem_
-----BEGIN CERTIFICATE-----
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
qxyM9d1tWuoAatRLGLE=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
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
pBjUv+3uXhpP63s9J7cUohKp/bTI6JFhA9OAgQ==
-----END CERTIFICATE-----    
_end_of_pem_

    CA_CERT = OpenSSL::X509::Certificate.new CA_CERT_PEM
    
    def self.generate_user_certificate private_key, public_key, dn, secure={}

      return CA_CERT.to_pem if secure[:secure]==:ca_cert_pem      
      #private_key = user_identity.get_private_key(password)
      #public_key = user_identity.public_key
      cert = ElectronicSignature.issue_cert(dn, public_key, 1, Time.now, Time.now+365*3600*24, [])
      return private_key.to_pem + CA_CERT.to_pem + cert.to_pem if secure[:secure]==true
      
      return OpenSSL::PKCS12.create(mangle_password(secure[:password]), secure[:display_name], private_key, cert, [CA_CERT]).to_der if secure[:secure]==:pkcs12
      return cert if secure[:secure]==:X509_object
      return CA_CERT.to_pem + cert.to_pem if secure[:secure]==:ca_and_user_cert_pem
      return cert.to_pem + CA_CERT.to_pem if secure[:secure]==:user_and_ca_cert_pem

      return cert.to_pem

    end

    def self.generate_keys user_identity, encrypt_with_password

      return nil if user_identity.nil? || encrypt_with_password.nil?

      objkey = user_identity.user_id
      salt = mangle_password(encrypt_with_password)

      key = OpenSSL::PKey::RSA.generate(2048)

      orig_private_key = key.to_pem.to_s

      public_key = key.public_key.to_pem

      private_key = DataEncryption.encrypt_data orig_private_key, objkey, salt

      return [private_key, public_key, orig_private_key]
    end

    def self.sign_data text, user_identity, password
      priv_key = user_identity.get_private_key(password)    
      digest = OpenSSL::Digest::SHA256.new
      signature = priv_key.sign(digest, text)

    end


    def self.sign_data_pkcs7 text, user_identity, password, format=nil

      # returns the signature for the text
      priv_key = user_identity.get_private_key(password)

      return :user_keys_not_set unless priv_key

      cert_pem = user_identity.get_certificate
      cert = OpenSSL::X509::Certificate.new(cert_pem)
      
      if format==:detached
        flags = OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
      else
        flags = OpenSSL::PKCS7::BINARY
      end
      OpenSSL::PKCS7.sign(cert, priv_key, text, [], flags)
    end

    def self.smime_data text, user_identity, password, subject, mime='text/html'

      #priv_key = user_identity.get_private_key(password)

      text = "Content-Type: #{mime}\n\n#{text}"
      pkcs7 = sign_data_pkcs7(text, user_identity, password, :detached)        

      res = OpenSSL::PKCS7.write_smime(pkcs7, text)

      "To: #{user_identity.email}\nFrom: #{user_identity.email}\nSubject: #{subject}\n#{res}"


    end  

  #  def self.validate_pkcs7_signature text, cert, user_identity
  #    pub_key = user_identity.get_public_key
  #
  #    
  #    pkcs7 = OpenSSL::PKCS7.new(cert)
  #    
  #    store = OpenSSL::X509::Store.new
  #    
  #    result = pkcs7.verify(cert, store, text)
  #    #signature = Base64.decode64(signature)
  #    if result#pub_key.verify(OpenSSL::Digest::SHA1.new, signature, text)
  #      return true
  #    else
  #      return false
  #    end    
  #
  #
  #  end
  #
  #  def self.validate_signature text, signature, user_identity
  #    
  #    public_key = user_identity.public_key
  #    return :user_keys_not_set if public_key.nil?
  #    pub_key = OpenSSL::PKey::RSA.new(public_key)
  #    signature = Base64.decode64(signature)
  #    
  #    pkcs7 = OpenSSL::PKCS7.read_smime(text)
  #    
  #    if pkcs7.verify #pub_key.verify(OpenSSL::Digest::SHA1.new, signature, text)
  #      return true
  #    else
  #      return false
  #    end    
  #  end


    def self.generate_checksum text
      Digest::SHA1.hexdigest text
    end


    def self.issue_cert dn, key, serial, not_before, not_after, extensions
      digest = OpenSSL::Digest::SHA1.new
      key = OpenSSL::PKey::RSA.new(key) if key.is_a?(String)
      cert = OpenSSL::X509::Certificate.new

      cert.version = 2
      cert.serial = serial || DateTime.now.to_i
      cert.subject = dn
      cert.issuer = CA_CERT.subject
      cert.public_key = key
      cert.not_before = not_before
      cert.not_after = not_after
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = CA_CERT
      if extensions.length==0
        extensions << ["basicConstraints", "CA:FALSE", true]
        extensions << ["keyUsage", "digitalSignature", true]
      end
      extensions.each{|oid, value, critical|
        cert.add_extension(ef.create_extension(oid, value, critical))
      }
      cert.sign(CA_PRIVATE_KEY, digest)
      cert
    end

    def issue_crl(revoke_info, serial, lastup, nextup, extensions,
                  issuer, issuer_key, digest)
      crl = OpenSSL::X509::CRL.new
      crl.issuer = issuer.subject
      crl.version = 1
      crl.last_update = lastup
      crl.next_update = nextup
      revoke_info.each{|serial, time, reason_code|
        revoked = OpenSSL::X509::Revoked.new
        revoked.serial = serial
        revoked.time = time
        enum = OpenSSL::ASN1::Enumerated(reason_code)
        ext = OpenSSL::X509::Extension.new("CRLReason", enum)
        revoked.add_extension(ext)
        crl.add_revoked(revoked)
      }
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.issuer_certificate = issuer
      ef.crl = crl
      crlnum = OpenSSL::ASN1::Integer(serial)
      crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", crlnum))
      extensions.each{|oid, value, critical|
        crl.add_extension(ef.create_extension(oid, value, critical))
      }
      crl.sign(issuer_key, digest)
      crl
    end


    def self.mangle_password pw
      # Do something to make the plain text password less guessable from outside the system, 
      # even though under the covers the password storage is not extractable due to a
      # using the password as a salt for the encryption
      # Additionally, we expect the password to be passed this service as a hash from an external system
      # adding extra security.
      # Thus the password only becomes guessable through the whole end to end system, removing one single 
      # link as a risk of breaking non-repudiation
      Digest::SHA256.hexdigest("09HGa278314ukl,mnLvkuDI2foI#{pw}ArrvbasPofy89ncr1Q7")      
    end



  private

    def self.ivsalt
      "akjsdf*&%jhdfyf98q++nTUnjkjo@i76d_347^82FP]89||'ujomcerfk^%$^Tuiyhhiunyhn904[[-=[[^!231n40c9cn2umio~%^78yniYBuinioh987x3421;93"
    end
  end
end