module  SecureApi

  class Response
  
    JSON = 'text/json'
    TEXT = 'text/plain'

    SUCCESS = 200
    OK = 200
    NOT_AUTHORIZED = 401
    TOKEN_TIMEOUT = 401
    UNPROCESSABLE = 422
    NOT_FOUND = 404
    BAD_REQUEST = 400
    CONFLICT = 409
  end

end