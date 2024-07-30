# frozen_string_literal: true

module Onetime
  class App # rubocop:disable Style/Documentation

    def translations
      publically do
        view = Onetime::App::Views::Translations.new req, sess, cust, locale
        res.body = view.render
      end
    end

    def contributors # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize
      publically do # rubocop:disable Metrics/BlockLength
        if !sess.authenticated? && req.post?
          sess.set_error_message "You'll need to sign in before agreeing."
          res.redirect '/signin'
        end
        if sess.authenticated? && req.post?
          if cust.contributor?
            sess.set_info_message "You are already a contributor!"
            res.redirect "/"
          else
            if !req.params[:contributor].to_s.empty? # rubocop:disable Style/NegatedIfElseCondition
              if !cust.contributor_at
                cust.contributor = req.params[:contributor]
                cust.contributor_at = Onetime.now.to_i unless cust.contributor_at
                cust.save
              end
              sess.set_info_message "You are now a contributor!"
              res.redirect "/"
            else
              sess.set_error_message "You need to check the confirm box."
              res.redirect '/contributor'
            end
          end
        else
          view = Onetime::App::Views::Contributor.new req, sess, cust, locale
          res.body = view.render
        end
      end
    end

    def forgot
      publically do
        if req.params[:key]
          secret = OT::Secret.load req.params[:key]
          if secret.nil? || secret.verification.to_s != 'true'
            raise OT::MissingSecret if secret.nil?
          else
            view = Onetime::App::Views::Forgot.new req, sess, cust, locale
            view[:verified] = true
            res.body = view.render
          end
        else
          view = Onetime::App::Views::Forgot.new req, sess, cust, locale
          res.body = view.render
        end
      end
    end

    def request_reset
      publically do
        if req.params[:key]
          logic = OT::Logic::ResetPassword.new sess, cust, req.params, locale
          logic.raise_concerns
          logic.process
          res.redirect '/signin'
        else
          logic = OT::Logic::ResetPasswordRequest.new sess, cust, req.params, locale
          logic.raise_concerns
          logic.process
          res.redirect '/'
        end
      end
    end

    def pricing
      res.redirect '/signup'
    end

    def signup
      publically do
        unless _auth_settings[:enabled] && _auth_settings[:signup]
          return disabled_response(req.path)
        end

        # If a plan has been selected, the next onboarding step is the actual signup
        if OT::Plan.plan?(req.params[:planid])
          sess.set_error_message "You're already signed up" if sess.authenticated?
          view = Onetime::App::Views::Signup.new req, sess, cust, locale
          res.body = view.render

        # Otherwise we default to showing the various account plans available
        else
          view = Onetime::App::Views::Signup.new req, sess, cust, locale
          res.body = view.render
        end
      end
    end

    def business_pricing
      publically do
        view = Onetime::App::Views::Plans.new req, sess, cust, locale
        view[:business] = true
        res.body = view.render
      end
    end

    def create_account
      publically do
        unless _auth_settings[:enabled] && _auth_settings[:signup]
          return disabled_response(req.path)
        end
        deny_agents!
        logic = OT::Logic::CreateAccount.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        if logic.autoverify
          sess = logic.sess
          cust = logic.cust
        end
        res.redirect '/'
      end
    end

    def login
      publically do
        res.redirect '/signin'
      end
    end

    def signin
      publically do
        unless _auth_settings[:enabled] && _auth_settings[:signin]
          return disabled_response(req.path)
        end
        view = Onetime::App::Views::Signin.new req, sess, cust, locale
        res.body = view.render
      end
    end

    def authenticate # rubocop:disable Metrics/AbcSize
      publically do
        unless _auth_settings[:enabled] && _auth_settings[:signin]
          return disabled_response(req.path)
        end
        # If the request is halted, say for example rate limited, we don't want to
        # allow the browser to refresh and re-submit the form with the login
        # credentials.
        no_cache!
        logic = OT::Logic::AuthenticateSession.new sess, cust, req.params, locale
        view = Onetime::App::Views::Signin.new req, sess, cust, locale
        if sess.authenticated?
          sess.set_info_message "You are already logged in."
          res.redirect '/'
        else
          if req.post? # rubocop:disable Style/IfInsideElse
            logic.raise_concerns
            logic.process
            sess = logic.sess
            cust = logic.cust
            is_secure = Onetime.conf[:site][:ssl]
            res.send_cookie :sess, sess.sessid, sess.ttl, is_secure
            if cust.role?(:colonel)
              res.redirect '/colonel/'
            else
              res.redirect '/'
            end
          else
            view.cust = OT::Customer.anonymous
            res.body = view.render
          end
        end
      end
    end

    def logout
      authenticated do
        logic = OT::Logic::DestroySession.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        res.redirect app_path('/')
      end
    end

    def account
      authenticated do
        logic = OT::Logic::ViewAccount.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        view = Onetime::App::Views::Account.new req, sess, cust, locale
        res.body = view.render
      end
    end

    def update_subdomain
      authenticated('/account') do
        logic = OT::Logic::UpdateSubdomain.new sess, cust, req.params, locale
        logic.raise_concerns
        logic.process
        res.redirect app_path('/account')
      end
    end

    private
    def _auth_settings
      OT.conf.dig(:site, :authentication)
    end

  end
end
