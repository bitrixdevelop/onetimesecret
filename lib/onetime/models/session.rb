
class Onetime::Session < Familia::HashKey
  @values = Familia::SortedSet.new name.to_s.downcase.gsub('::', Familia.delim).to_sym, db: 1

  include Onetime::Models::RedisHash
  include Onetime::Models::RateLimited

  # When set to true, the session reports itself as not authenticated
  # regardless of the value of the authenticated field. This allows
  # the site to disable authentication without affecting the session
  # data. For example, if we want to disable authenticated features
  # temporarily (in case of abuse, etc.) we can set this to true so
  # the user will remain signed in after we enable authentication again.
  #
  # During the time that authentication is disabled, the session will
  # be anonymous and the customer will be anonymous.
  attr_accessor :disable_auth

  def initialize ipaddress, custid, useragent=nil
    @ipaddress = ipaddress
    @custid = custid
    @useragent = useragent

    # Defaulting the session ID to nil ensures we can't persist this instance
    # to redis until one is set (see `RedisHash#check_identifier!`). This is
    # important b/c we don't want to be colliding a default session ID and risk
    # leaking session data (e.g. across anonymous users).
    #
    # This is the distinction between .new and .create. .new is a new session
    # that hasn't been saved to redis yet. .create is a new session that has
    # been saved to redis.
    @sessid = nil

    @disable_auth = false

    OT.ld "[Session.initialize] Initialized session (not saved) #{self}"
    super name, db: 1, ttl: 20.minutes
  end

  def sessid= sid
    @sessid = sid
    @name = name
    @sessid
  end

  def set_form_fields hsh
    self.form_fields = hsh.to_json unless hsh.nil?
  end

  def get_form_fields!
    fields_json = self.form_fields!
    return if fields_json.nil?
    OT::Utils.indifferent_params Yajl::Parser.parse(fields_json)
  end

  def identifier
    @sessid  # Don't call the method
  end

  # The external identifier is used by the rate limiter to estimate a unique
  # client. We can't use the session ID b/c the request agent can choose to
  # not send cookies, or the user can clear their cookies (in both cases the
  # session ID would change which would circumvent the rate limiter). The
  # external identifier is a hash of the IP address and the customer ID
  # which means that anonymous users from the same IP address are treated
  # as the same client (as far as the limiter is concerned). Not ideal.
  #
  # To put it another way, the risk of colliding external identifiers is
  # acceptable for the rate limiter, but not for the session data. Acceptable
  # b/c the rate limiter is a temporary measure to prevent abuse, and the
  # worse case scenario is that a user is rate limited when they shouldn't be.
  # The session data is permanent and must be kept separate to avoid leaking
  # data between users.
  def external_identifier
    elements = []
    elements << ipaddress || 'UNKNOWNIP'
    elements << custid || 'anon'
    @external_identifier ||= elements.gibbler.base(36)
    OT.ld "[Session.external_identifier] sess identifier input: #{elements.inspect} (result: #{@external_identifier})"
    @external_identifier
  end

  def stale?
    self[:stale].to_s == 'true'
  end

  def update_fields hsh={}
    hsh[:sessid] ||= sessid
    super hsh
  end

  def update_sessid
    self.sessid = self.class.generate_id
  end

  def replace!
    @custid ||= self[:custid]
    newid = self.class.generate_id

    # Rename the existing key in redis if necessary
    rename name(newid) if exists?
    self.sessid = newid

    clear_cache

    # This update is important b/c it ensures that the
    # data gets written to redis.
    update_fields :stale => 'false', :sessid => newid
    sessid
  end

  def shrimp? guess
    shrimp = self[:shrimp].to_s
    (!shrimp.empty?) && shrimp == guess.to_s
  end

  def add_shrimp
    self.shrimp ||= self.class.generate_id
    self.shrimp
  end

  def clear_shrimp!
    delete :shrimp
    nil
  end

  def authenticated?
    !disable_auth && authenticated.to_s == 'true'
  end

  def anonymous?
    disable_auth || sessid.to_s == 'anon' || sessid.to_s.empty?
  end

  def load_customer
    return OT::Customer.anonymous if anonymous?
    cust = OT::Customer.load custid
    cust.nil? ? OT::Customer.anonymous : cust
  end

  def unset_error_message
    self.error_message = nil
  end

  def set_error_message msg
    self.error_message = msg
  end

  def set_info_message msg
    self.info_message = msg
  end

  def session_group groups
    sessid.to_i(16) % groups.to_i
  end

  def opera?()            @agent.to_s  =~ /opera/i                      end
  def firefox?()          @agent.to_s  =~ /firefox/i                    end
  def chrome?()          !(@agent.to_s =~ /chrome/i).nil?               end
  def safari?()           (@agent.to_s =~ /safari/i && !chrome?)        end
  def konqueror?()        @agent.to_s  =~ /konqueror/i                  end
  def ie?()               (@agent.to_s =~ /msie/i && !opera?)           end
  def gecko?()            (@agent.to_s =~ /gecko/i && !webkit?)         end
  def webkit?()           @agent.to_s  =~ /webkit/i                     end
  def superfeedr?()       @agent.to_s  =~ /superfeedr/i                 end
  def google?()           @agent.to_s  =~ /google/i                     end
  def yahoo?()            @agent.to_s  =~ /yahoo/i                      end
  def yandex?()           @agent.to_s  =~ /yandex/i                     end
  def baidu?()            @agent.to_s  =~ /baidu/i                      end
  def searchengine?()
    @agent.to_s  =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg|Yahoo|bing|superfeedr)\b/i
  end

  module ClassMethods
    attr_reader :values

    def add sess
      self.values.add OT.now.to_i, sess.identifier
      self.values.remrangebyscore 0, OT.now.to_i-2.days
    end

    def all
      self.values.revrangeraw(0, -1).collect { |identifier| load(identifier) }
    end

    def recent duration=30.days
      spoint, epoint = OT.now.to_i-duration, OT.now.to_i
      self.values.rangebyscoreraw(spoint, epoint).collect { |identifier| load(identifier) }
    end

    def exists? sessid
      sess = new nil, nil
      sess.sessid = sessid
      sess.exists?
    end

    def load sessid
      sess = new nil, nil
      sess.sessid = sessid
      sess.exists? ? (add(sess); sess) : nil  # make sure this sess is in the values set
    end

    def create ipaddress, custid, useragent=nil
      sess = new ipaddress, custid, useragent

      OT.ld "[Session.create] Creating new session #{sess}"

      # force the storing of the fields to redis
      sess.update_sessid
      sess.ipaddress, sess.custid, sess.useragent = ipaddress, custid, useragent
      sess.save
      add sess # to the @values sorted set
      sess
    end

    def generate_id
      input = SecureRandom.hex(32)  # 16=128 bits, 32=256 bits
      # Not using gibbler to make sure it's always SHA256
      Digest::SHA256.hexdigest(input).to_i(16).to_s(36) # base-36 encoding
    end
  end

  extend ClassMethods
end
