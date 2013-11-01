em-secure-api
=============

**em-secure-api** makes it easy to build REST / JSON APIs in Ruby that are secure, fast and reliable.

em-secure-api automatically validates requests for authenticity, completeness and uniqueness, checks 
client authorization and uses a simple routing configuration to connect the API to the implementation.
With the security and wiring addressed, a developer can focus on building the functionality that makes the API useful.

And by building on EventMachine and the reactor pattern, API services built with em-secure-api can be made fast and scalable.
Simply run multiple em-secure-api servers on separate ports and load balance with 
[HAProxy](http://haproxy.1wt.eu/), 
[Nginx](http://wiki.nginx.org/Main) or 
[Apache2](http://httpd.apache.org/).


Why em-secure-api?
------------------

There are already Ruby frameworks that can help you build APIs running 
on [EventMachine](https://github.com/eventmachine/eventmachine). They leave a lot of the decisions about securing your service up
to the developer, leading to a lot of extra work.

**em-secure-api** aims to take the API security decisions away from the developer, so 
that he or she can focus on implementation of the actual functionality, while ensuring 
the service is as secure as possible. If you want to virtually guarantee that you are 
only handling requests that are authentic and valid, then this lightweight framework 
strives to give you that.

The primary aims of em-secure-api are:

  * enforce access by registered clients only
  * ensure only valid requests are received, with request signing
  * prevent duplicate requests from being processed, using a one-time token ('nonce')
  * validate that the correct set of request parameters are provided
  * ensure that valid requests are not so old that they are invalid
  * attempt to secure configuration files to limit access to database credentials
  * provide flexible configurations (such as token timeouts) for individual actions

If you are looking just for simple, unsigned API processing, where you consider the 
internal network to be your primary measure of security, then em-secure-api may be
more than you need (since it adds a little work on the admin and client development side).

If you need to implement secure services in a secure environment, potentially on cloud servers,
em-secure-api aims provides some trusted security approaches with minimal coding effort.

Beta
------------------

This software is still in early beta. Many things could change and it may break. Please add
any issues and I'll try and get to them fast. 

If you'd like to contribute, please let me know. Any new ideas, tests, sample implementations,
and tests would be much appreciated!

Installation
------------------

This is not a gem, just a simple set of source that rides the EventMachine. Get the 
source by download the package (or clone the Git repo locally). 

cd to the directory then run 

    ./script/setup.sh root

(replace root with your mySQL admin username if necessary)

To run the server in the background for testing:

    eval "ruby lib/em_server.rb &"; empid=$!;

(hit return again for the command line)

To run your tests

    rspec

To stop the server:

    kill $empid

Calling with a client
---------------------

A 'client' on em-secure-api can be a single server on a security conscious internal network, 
or an authorized API user externally. So let's start by viewing the service from the client
point of view, and seeing how it prevents requests being tampered with, duplicated, or being
so old they are now irrelevant.

To start, run a script to add a new client and shared secret to the database list of authorized clients.

    scripts/add_client.sh test_client-irb true

Returns this:

- Shared Secret:20a6250f1dc3f9e56cbbf4576016e517a066092d759402e9fa79dc0c64c0adfd

Now try making some secure calls

    require './lib/secure_api/api_auth_gen'
    params = {username: 'phil', password: 'hello phil', opt1: 'this', client: 'test_client-irb'} 
    action = 'action1'
    controller = 'controller1'
    secret = '20a6250f1dc3f9e56cbbf4576016e517a066092d759402e9fa79dc0c64c0adfd'
    uri = SecureApi::ApiAuth.generate_uri params, action, controller, secret: secret

Now make the call with your favorite HTTP library

    require 'net/http'
    res = Net::HTTP.get_response 'localhost' , uri, 5501
    puts res.code, res.body
    #---> OK

Try reusing the same request

    res = Net::HTTP.get_response 'localhost' , uri, 5501
    puts res.code, res.body
    #---> nope, not allowed

Clear the added timestamp & recreate the request

    params.delete :timestamp
    uri = SecureApi::ApiAuth.generate_uri params, action, controller, secret: secret
    res = Net::HTTP.get_response 'localhost' , uri, 5501
    puts res.code, res.body
    #---> OK

Recreate the request, but this time we'll "tamper" with a value

    params.delete :timestamp
    uri = SecureApi::ApiAuth.generate_uri params, action, controller, secret: secret
    uri.gsub! "opt1=this", "opt1=th!s"
    res = Net::HTTP.get_response 'localhost' , uri, 5501
    puts res.code, res.body
    #---> You can't cheat this

 How about posting?

    # A different set of parameters
    params = {username: 'phil', password: 'hello phil', opt1: 'this', opt2: 'more', opt3: 'go for it', client: 'test_client-irb'}
    # Generate the 'form' to post (to a different controller this time)
    post_form_params = SecureApi::ApiAuth.generate_form(params, 'action1', 'controller2', secret: secret)
    
    uri = URI("http://localhost:5501/controller2/action1")
    res = Net::HTTP.post_form(uri, post_form_params)
    puts res.code, res.body
    #---> OK and some different logic produced the JSON result

And timeouts? How long before the request is considered too old to accept?

    params = {client: 'test_client-irb'}
    uri = SecureApi::ApiAuth.generate_uri params, 'status', 'admin', secret: secret
    sleep 6
    res = Net::HTTP.get_response 'localhost' , uri, 5501
    puts res.code, res.body
    #---> Nope, too old

You should note that the timeout for the server can be set in the configuration, and defaults to 30 seconds.

Implementing your API
------------------

An API call (a GET has been used for clarity) looks like:
/controller1/action1?opt1=nnn&opt2=hhh&client=test_client&timestamp=234234&ottoken=23ah4sdf2e3443

Parameters opt1 and opt2 represent your actual API parameters, which are configurable,
and drive your business logic.

The client, timestamp and ottoken handle the security, authenticity and uniqueness of
requests, and a couple of Ruby methods are provided to create them automatically, so 
you don't have to worry about signing requests on the client or validating them on 
the server.

Then all you have to do for implementation is:

** Setup your routes and rules for required parameters **

    def routes
      {
        controller1: {
          __default_parameters: {username: :req, password: :req},
          action1_get: {params: {opt1: :req, opt2: :opt } },
          action2_post: {params: {opt1: :req, opt2: :req, password: :opt } },
        },
        admin: {
          status_get: {params: {check_me: :opt} }
        }
      }
    end

** Implement each route **

    def admin_status_get
      if compare_result(params[:check_me])
        set_response status: Response::OK, content_type: Response::JSON, content: {} 
      else
        throw :not_processed_request, status: Response::BAD_REQUEST, content_type: Response::TEXT, content: "I'm not so good" 
      end
    end

Routing requests
------------------

Looking at the sample implementation in `lib/api_models/implementation.rb`, you'll see
a method named `routes`

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
          action3_post: {}
        },
        admin: {
          status_get: {}
        }
      }
    end

Simply, this defines how requests are routed to the actual implementation. Using the
example API above, you'll see the request path `/controller1/action1?` corresponds to
the first hash key 'controller1' and within it, the key for an actual route,
'action1_get', since this is a GET request.

Within this action's route definition, we state the parameters that are expected to be 
passed with the request. These are merge with the `__default_parameters` to allow common
default parameters to be defined once, then overridden for each action. 

The options are: 

  *    :req = required
  *    :opt = optional
  *    :exc = exclude (ensure this is not provided)

The standard server implementation enforces these definitions (except for opt, which
is currently really only to assist documentation).

If a request meets the required parameters, then it will call a method in the implementation
with the name that matches the controller and route key: e.g. `controller1_action1_get`. 
Within this the developer can then call to any required business logic.

Implementing requests
------------------

The following snippet shows how an action implementation might look:

    def controller1_action1_get
      opt1 = params[:opt1].upcase
      opt2 = "#{params[:opt2].upcase} has been forced to upper case" if params[:opt2]
      set_response  status: Response::OK , content_type: Response::JSON, content: {opt1: opt1, opt2: opt2} 
    end

Implementations can return a standard HTTP response code (as constant or integer), 
content_type as Response::JSON or Response::TEXT, and appropriate matching content.

In order to simplify flow, you can throw a :not_processed_request, which will be caught
by the server. For example:

    throw :not_processed_request, {:status=>Response::NOT_FOUND, :content_type=>Response::TEXT ,:content=>"no such record"}

This will end the routed request processing, while allowing any cleanup logic to occur.

All responses, either thrown or set_response will automatically generate JSON from 
an appropriate Ruby structure if the content_type is set to Response::JSON. 

Before and After
------------------

Each controller can optionally define a before and after handler, for a 
method (_get, _post). 

For example:

    def before_controller2_get
      if param[:username] != 'phil'
        throw :not_processed_request, {:status=>Response::NOT_FOUND, :content_type=>Response::TEXT ,:content=>"no such record"}
      end      
    end

    def after_controller2_get
      if param[:password] == 'not secret'
        set_response status: Response::BAD_REQUEST, content_type: Response::TEXT, content: 'This password is not secret.'
      end      
    end

As you can see, you can use `throw` to prevent further processing, or you can 
`set_response` which for 'after_...' will override previous responses and for 
'before_...' will set a default response which may be overridden by the 
actual route action, or the `after...`. Any throw will prevent additional processing
of the request, and will immediately result is a return of the thrown hash, 
irrespective of previously set_response values.

Returning other content types
------------------

Perhaps you need to respond with a content type that is not text/plain or text/json. 
That's fine, just set_response with content_type: 'some/type' and format your content
string appropriately.

The 'after_controller' handlers described above are a great place to do this if you
need a consistent format for your responses after all the business logic has been done.

Securing the configuration
------------------

The configuration file is stored locally. Since it contains your database credentials, 
plus other possibly sensitive information, it is encrypted. The encryption key is 
stored in a memory-based file system (/dev/shm), available by default on many 
Linux installations. 

The aim is that by keeping the key on temporary storage, it will not be less simple 
for an unauthorized user who made it onto your server to find and compromise the data. 

The key is then used only at server startup to unencrypt the configuration file. In 
the future, it is planned to only retrieve the key from an external key server, 
or through some kind of 'port knocking' system. The aim is to make the key as 
transient as possible, to make it as hard as possible for an unauthorized user 
to access the configuration and hence the database.

Create database, file structure, etc
------------------

The database provides storage for the list of registered clients, and for logging of
requests so that one-time use can be enforced.

Current the service only supports mySQL. Contributions for other persistence are welcome!

    ./scripts/setup.sh root

(note: change root to your mysql administrative username if necessary)

When prompted, enter the password for your mySQL user.


NOTE: in the future this user should really only have READ access on the clients 
table, ensuring that the running API service can not add clients accidentally. A
second administrative only user should be used on a separate database connection 
for administrative client add / remove tasks, who would have full read/write access.
This user would not be used for any direct API access (or we would limit this


To setup the configuration file:
------------------

The initial installation creates a database and user with default password. If you change the 
username or password of this database user, you'll need to reconfigure the config.yml file.

Since the config is encrypted, use the following script to do it.Edit the following 
script for the log file directory to match and select the port to 
run the EM server.The database user name is gen_api and password ja89jh in the initial script.

Then run the command below, which creates and encrypts the config.

ruby -r "./lib/helpers/config_manager.rb" -e "ConfigManager.create_database_config('utf8','mysql2',
         're_svc_records', # db name
         'gen_api', #db username
         'ja89jh',  #db password
         { directories: {
           log: './log' # log file location (relative to base directory, or full path)
         }, 
         server: {
           port: 5501,  # port to run the server on
           request_timeout: {  # max time between timestamp and current time (in ms)
              __default: 30000,   # default for all requests
              controller1: {
                __default:10000,   # default for requests to controller1
                action3_get: 60000  # override controller default for action3 get request
              },
              admin: {
                status_get: 5000 # override server default for status get request
              }
           }           
         }  } )"


Then `sudo crontab -e`
copy the text returned by the above script into the following string and paste at the top of the crontab:

    @reboot /bin/echo -e 'text goes here' > /dev/shm/.re_keys.general_api

This will replace your config on every reboot.

Adding clients to the authorized list
------------------------------------------------

The clients table in the database holds the authorized list of clients. Simple enough. 
But each has a shared secret that needs to be generated. 

* Add a client 
- checks and prevents an existing client being replaced, and therefore protects existing shared_secret
- returns shared secret value

    scripts/add_client.sh clientname

* Replace (or add) a client
- will overwrite and existing client
- returns shared secret value

    scripts/add_client.sh clientname true

* Delete a client
- note that the 'confirm' text is required after the clientname, otherwise the request is ignored.

    scripts/delete_client.sh clientname confirm

Testing
------------------

A set of tests exercise the backend authorization functionality and gently probe 
a skeleton API implementation. The API implementation is, in 
`lib/api_models/implementation.rb` provides a few functions to get started, and
is easily edited to plug in a real implementation.

To run the server in the foreground:

ruby lib/em_server.rb

To run the server in the background for testing:

    eval "ruby lib/em_server.rb &"; empid=$!;

To stop the server:

    kill $empid

The Rspec tests require a server to be running. It assumes it is on localhost. Run with:

    rspec

Running multiple servers sharing the same configuration
-------------------------------------------------------

Since you'll probably want to run multiple servers on different ports, all providing the 
same implementation and configuration file, just use the following argument when starting
the server

    ruby lib/em_server.rb --port=5555

replace the port with your preferred port number.

Note that when running multiple servers in the background using `eval` you'll need to track
the process IDs yourself for killing the services.

Creating an EM server as a Linux Upstart service
------------------


    description     "EM Server"
    start on (starting network-interface
     or starting network-manager
     or starting networking)
    stop on runlevel [!2345]
    exec {installation directory}/start_em_service_upstart.sh
    respawn


License for em-secure-api
------------------

Copyright (c) 2013 Phil Ayres https://github.com/philayres

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

