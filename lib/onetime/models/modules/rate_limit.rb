# frozen_string_literal: true

class Onetime::RateLimit < Familia::String
  DEFAULT_LIMIT = 25 unless defined?(OT::RateLimit::DEFAULT_LIMIT)
  ttl 20.minutes
  def initialize identifier, event
    super [:limiter, identifier, event, self.class.eventstamp], :db => 2
  end
  alias_method :count, :to_i
  class << self
    attr_reader :events
    def incr! identifier, event
      lmtr = new identifier, event
      count = lmtr.increment
      lmtr.update_expiration
      OT.ld [:limit, event, identifier, count].inspect
      if exceeded?(event, count)
        raise OT::LimitExceeded.new(identifier, event, count)
      end
      count
    end
    alias_method :increment!, :incr!
    def clear! identifier, event
      lmtr = new identifier, event
      ret = lmtr.clear
      OT.ld [:clear, event, identifier, ret].inspect
      ret
    end
    def exceeded? event, count
      (count) > (events[event] || DEFAULT_LIMIT)
    end
    def register_event event, count
      (@events ||= {})[event] = count
    end
    def register_events events
      (@events ||= {}).merge! events
    end
    def eventstamp
      now = OT.now.to_i
      rounded = now - (now % self.ttl)
      Time.at(rounded).utc.strftime('%H%M')
    end
  end
end