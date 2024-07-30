require_relative 'v1/base'
require_relative '../base'  # app/base.rb

class Onetime::App
  class API
    include AppSettings
    include Onetime::App::API::Base

    @check_utf8 = true
    @check_uri_encoding = true

    def status
      authorized(true) do
        sess.event_incr! :check_status
        json :status => :nominal, :locale => locale
      end
    end

    def share
      authorized(true) do
        req.params[:kind] = :share
        logic = OT::Logic::CreateSecret.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if req.get?
          res.redirect app_path(logic.redirect_uri)
        else
          secret = logic.secret
          json metadata_hsh(logic.metadata,
                              :secret_ttl => secret.realttl,
                              :passphrase_required => secret && secret.has_passphrase?)
        end
      end
    end

    def generate
      authorized(true) do
        req.params[:kind] = :generate
        logic = OT::Logic::CreateSecret.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if req.get?
          res.redirect app_path(logic.redirect_uri)
        else
          secret = logic.secret
          json metadata_hsh(logic.metadata,
                              :value => logic.secret_value,
                              :secret_ttl => secret.realttl,
                              :passphrase_required => secret && secret.has_passphrase?)
          logic.metadata.viewed!
        end
      end
    end

    def show_metadata
      authorized(true) do
        logic = OT::Logic::ShowMetadata.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        secret = logic.metadata.load_secret
        if logic.show_secret
          secret_value = secret.can_decrypt? ? secret.decrypted_value : nil
          json metadata_hsh(logic.metadata,
                              :value => secret_value,
                              :secret_ttl => secret.realttl,
                              :passphrase_required => secret && secret.has_passphrase?)
        else
          json metadata_hsh(logic.metadata,
                              :secret_ttl => secret ? secret.realttl : nil,
                              :passphrase_required => secret && secret.has_passphrase?)
        end
        logic.metadata.viewed!
      end
    end

    def show_metadata_recent
      authorized(false) do
        logic = OT::Logic::ShowRecentMetadata.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        recent_metadata = logic.metadata.collect { |md|
          next if md.nil?
          hash = metadata_hsh(md)
          hash.delete :secret_key   # Don't call md.delete, that will delete from redis
          hash
        }.compact
        json recent_metadata
      end
    end

    def show_secret
      authorized(true) do
        req.params[:continue] = 'true'
        logic = OT::Logic::ShowSecret.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if logic.show_secret
          json :value => logic.secret_value, :secret_key => req.params[:key]

          # Immediately mark the secret as viewed, so that it
          # can't be shown again. If there's a network failure
          # that prevents the client from receiving the response,
          # we're not able to show it again. This is a feature
          # not a bug.
          logic.secret.received!
        else
          secret_not_found_response
        end
      end
    end

    # curl -X POST -u 'EMAIL:APIKEY' http://LOCALHOSTNAME:3000/api/v1/private/:key/burn
    def burn_secret
      authorized(true) do
        req.params[:continue] = 'true'
        logic = OT::Logic::BurnSecret.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if logic.greenlighted
          json :state           => metadata_hsh(logic.metadata),
               :secret_shortkey => logic.metadata.secret_shortkey
        else
          secret_not_found_response
        end
      end
    end

    def create
      authorized(true) do
        req.params[:kind] = :share
        logic = OT::Logic::CreateSecret.new sess, cust, req.params, locale
        logic.token = ''.instance_of?(String).to_s  # lol a roundabout way to get to "true"
        logic.raise_concerns
        logic.process
        if req.get?
          res.redirect app_path(logic.redirect_uri)
        else
          secret = logic.secret
          json metadata_hsh(logic.metadata,
                              :secret_ttl => secret.realttl,
                              :passphrase_required => secret && secret.has_passphrase?)
        end
      end
    end

    # Endpoints for interactive UI (v1)
    #
    # The response objects are minimal, and are intended to be used
    # by the client to determine the next step in the UI flow. The
    # client should not rely on the response object for any data
    # other than the success flag, error messages.
    #
    # This is an intentional limitation to keep the API simple and
    # while we transition to a V2 API that will be more feature-rich.
    #
    def generate_apikey
      authorized do
        logic = OT::Logic::GenerateAPIkey.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if logic.greenlighted
          json :success => true, :custid => cust.custid, :apikey => logic.apikey
        else
          error_response "API Key could not be generated."
        end
      end
    end

    def change_account_password
      authorized do
        logic = OT::Logic::UpdateAccount.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if logic.greenlighted
          json :success => true, :custid => cust.custid
        else
          error_response "Password could not be changed."
        end
      end
    end

    def destroy_account
      authorized do
        logic = OT::Logic::DestroyAccount.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if logic.greenlighted
          json :success => true, :custid => cust.custid
        else
          error_response "Account could not be destroyed."
        end
      end
    end

    private
    def metadata_hsh md, opts={}
      hsh = md.all
      secret_ttl = opts[:secret_ttl] ?
        opts[:secret_ttl].to_i : md.realttl.to_i
      ret = {
        :custid => hsh['custid'],
        :metadata_key => hsh['key'],
        :secret_key => hsh['secret_key'],
        :ttl => hsh['ttl'].to_i,
        :metadata_ttl => md.realttl.to_i,
        :secret_ttl => secret_ttl,
        :state => hsh['state'] || 'new',
        :updated => hsh['updated'].to_i,
        :created => hsh['created'].to_i,
        :received => hsh['received'].to_i,
        :recipient => [hsh['recipients']].flatten.compact.uniq
      }
      if ret[:state] == 'received'
        ret.delete :secret_ttl
        ret.delete :secret_key
      else
        ret.delete :received
      end
      ret[:value] = opts[:value] if opts[:value]
      if !opts[:passphrase_required].nil?
        ret[:passphrase_required] = opts[:passphrase_required]
      end
      ret
    end


  end
end
