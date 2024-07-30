# frozen_string_literal: true

# These tryouts test the session management functionality in the OneTime application.
# They cover various aspects of session handling, including:
#
# 1. Session creation and initialization
# 2. Session identifiers and attributes
# 3. Form field management within sessions
# 4. Authentication status and auth disabling
# 5. Session reloading and replacement
#
# These tests aim to verify the correct behavior of the OT::Session class,
# which is crucial for maintaining user state and security in the application.
#
# The tryouts simulate different session scenarios and test the OT::Session class's
# behavior without needing to run the full application, allowing for targeted testing
# of these specific features.

require_relative '../lib/onetime'

# Use the default config file for tests
OT::Config.path = File.join(__dir__, '..', 'etc', 'config.test')
OT.boot!

@ipaddress = '10.0.0.254' # A private IP address
@useragent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_2_5) AppleWebKit/237.36 (KHTML, like Gecko) Chrome/10.0.95 Safari/237.36'
@custid = 'tryouts'

@sess = OT::Session.create @ipaddress, @custid, @useragent

## Sessions have a NIL session ID when _new_ is called
sess = OT::Session.new @ipaddress, @custid, @useragent
sessid = sess.sessid
[sessid.class, sessid]
#=> [NilClass, nil]

## Sessions have a session ID when _create_ is called
sessid = @sess.sessid
[sessid.class, (48..52).include?(sessid.length)]
#=> [String, true]

## Sessions have a unique session ID when _create_ is called the same arguments
@sess = OT::Session.create @ipaddress, @custid, @useragent
sess = OT::Session.create @ipaddress, @custid, @useragent
sessid1 = @sess.sessid
sessid2 = sess.sessid
[sessid1.eql?(sessid2), sessid1.eql?(''), sessid1.class, sessid2.class, sessid2.to_i(36).positive?, sessid2.to_i(36).positive?]
#=> [false, false, String, String, true, true]

## Sessions have an identifier
identifier = @sess.identifier
[identifier.class, (48..52).include?(identifier.length)]
#=> [String, true]

## Sessions have a short identifier
short_identifier = @sess.short_identifier
[short_identifier.class, short_identifier.length]
#=> [String, 12]

## Sessions have an IP address
ipaddress = @sess.ipaddress
[ipaddress.class, ipaddress]
#=> [String, @ipaddress]

## Sessions don't get unique IDs when instantiated
s1 = OT::Session.new '255.255.255.255', :anon
s2 = OT::Session.new '255.255.255.255', :anon
s1.sessid.eql?(s2.sessid)
#=> true

## Can set form fields
ret = @sess.set_form_fields custid: 'tryouts', planid: :testing
ret.class
#=> String

## Can get form fields, with indifferent access via symbol or string
ret = @sess.get_form_fields!
[ret.class, ret[:custid], ret['custid']]
#=> [Hash, 'tryouts', 'tryouts']

## By default sessions do not have auth disabled
sess = OT::Session.create @ipaddress, @custid, @useragent
sess.disable_auth
#=> false

## Can set and get disable_auth
sess = OT::Session.create @ipaddress, @custid, @useragent
sess.disable_auth = true
sess.disable_auth
#=> true

## By default sessions are not authenticated
sess = OT::Session.create @ipaddress, @custid, @useragent
sess.authenticated?
#=> false

## Can set and check authenticated status
sess = OT::Session.create @ipaddress, @custid, @useragent
sess.authenticated = true
sess.authenticated?
#=> true

## Can force a session to be unauthenticated
@sess_disabled_auth = OT::Session.create @ipaddress, @custid, @useragent
@sess_disabled_auth.authenticated = true
@sess_disabled_auth.disable_auth = true
@sess_disabled_auth.authenticated?
#=> false

## Load a new instance of the session and check authenticated status
sess = OT::Session.load @sess_disabled_auth.sessid
[sess.authenticated?, sess.disable_auth]
#=> [true, false]

## Reload the same instance of the session and check authenticated status
@sess_disabled_auth.reload!
[@sess_disabled_auth.authenticated?, @sess_disabled_auth.disable_auth]
#=> [false, true]


## Replacing the session ID will update the session
@replaced_session = OT::Session.create @ipaddress, @custid, @useragent
initial_sessid = @replaced_session.sessid.to_s
@replaced_session.authenticated = true
@replaced_session.replace!


@replaced_session.sessid.eql?(initial_sessid)
#=> false

## Replaced session is not authenticated


## Can check if a session exists
OT::Session.exists? @sess.sessid
#=> true

## Can load a session
sess = OT::Session.load @sess.sessid
sess.sessid.eql?(@sess.sessid)
#=> true

## Can generate a session ID
sid = OT::Session.generate_id
[sid.class, (48..52).include?(sid.length)]
#=> [String, true]

## Can update fields
@sess_with_changes = OT::Session.create @ipaddress, @custid, @useragent
@sess_with_changes.update_fields custid: 'tryouts', planid: :testing
#=> "OK"

## Can update fields (verify changes)
[@sess_with_changes.custid, @sess_with_changes.planid]
#=> ["tryouts", "testing"]
