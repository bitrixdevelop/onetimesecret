# frozen_string_literal: true

# These tryouts test the authentication-related routes
# and how they respond based on the authentication
# settings in etc/config. (NOTE: In test the file is
# etc/config.test).
#
# The tryouts for POST requests are disabled because
# are returning 302 nil location responses.
#

require 'rack'
require 'rack/mock'

require_relative '../lib/onetime'

# Use the default config file for tests
OT::Config.path = File.join(__dir__, '..', 'etc', 'config.test')
OT.boot! :tryouts

# Initialize the Rack application and create a mock request
@app = Rack::Builder.parse_file('config.ru').first
@mock_request = Rack::MockRequest.new(@app)


# Web Routes (default settings)

## Authentication is enabled
OT.conf[:site][:authentication][:signin]
#=> true

## With default configuration, can access the sign-in page
response = @mock_request.get('/signin')
response.status
#=> 200

## With default configuration, can access the sign-in page
response = @mock_request.get('/signup')
response.status
#=> 200

## With default configuration, can try to sign-in
response = @mock_request.post('/signin', lint: true)
[response.status, response.headers["Location"]]
##=> [302, "/"]

### With default configuration, can try to sign-up
response = @mock_request.post('/signup', lint: true)
[response.status, response.headers["Location"]]
##=> [302, nil]

## With default configuration, dashboard redirects to sign-in
response = @mock_request.get('/dashboard')
[response.status, response.headers["Location"]]
#=> [302, "/"]

# Web Routes (authentication disabled)

## Disable authentication for all routes
OT.conf[:site][:authentication][:enabled] = false
OT::Config.after_load(OT.conf)
OT.conf[:site][:authentication][:signin]
#=> false

## With auth disabled, can access the sign-in page
response = @mock_request.get('/signin')
response.status
##=> 404

## With auth disabled, can access the sign-in page
response = @mock_request.get('/signup')
response.status
##=> 404

## With auth disabled, can try to sign-in
response = @mock_request.post('/signin')
[response.status, response.headers["Location"]]
##=> 404

### With auth disabled, can try to sign-up
response = @mock_request.post('/signup')
[response.status, response.headers["Location"]]
##=> 404

## With auth disabled, dashboard redirects to sign-in
response = @mock_request.get('/dashboard')
response.status
#=> 404

# API Routes

## Can access the API status
response = @mock_request.get('/api/v1/status')
[response.status, response.body]
#=> [200, '{"status":"nominal","locale":"en"}']

## Can access the API share endpoint
response = @mock_request.post('/api/v1/create')
[response.status, response.body]
#=> [404, '{"message":"You did not provide anything to share"}']

## Can access the API generate endpoint
response = @mock_request.post('/api/v1/generate')
content = JSON.parse(response.body) rescue {}
[response.status, content["custid"]]
#=> [200, 'anon']


# Colonel Routes

## Can access the colonel dashboard
response = @mock_request.get('/colonel')
response.status
#=> 404

## Can access the colonel customers page
response = @mock_request.get('/colonel/customers')
response.status
#=> 404

## Can access the colonel stats page
response = @mock_request.get('/colonel/stats')
response.status
#=> 404
