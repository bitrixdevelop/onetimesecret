
module Onetime
  class Plan
    class << self
      attr_reader :plans

      def add_plan(planid, *args)
        @plans ||= {}
        new_plan = new(planid, *args)
        plans[new_plan.planid] = new_plan
        plans[new_plan.planid.gibbler.short] = new_plan
      end

      def normalize(planid)
        planid.to_s.downcase
      end

      def plan(planid)
        plans[normalize(planid)]
      end

      def plan?(planid)
        plans.member?(normalize(planid))
      end

      def load_plans!
        add_plan :anonymous, 0, 0, ttl: 7.days, size: 1_000_000, api: false, name: 'Anonymous'
        add_plan :personal_v1, 5.0, 1, ttl: 14.days, size: 1_000_000, api: false, name: 'Personal'
        add_plan :personal_v2, 10.0, 0.5, ttl: 30.days, size: 1_000_000, api: true, name: 'Personal'
        add_plan :personal_v3, 5.0, 0, ttl: 14.days, size: 1_000_000, api: true, name: 'Personal'
        add_plan :professional_v1, 30.0, 0.50, ttl: 30.days, size: 1_000_000, api: true, cname: true,
                                               name: 'Professional'
        add_plan :professional_v2, 30.0, 0.333333, ttl: 30.days, size: 1_000_000, api: true, cname: true,
                                                   name: 'Professional'
        add_plan :agency_v1, 100.0, 0.25, ttl: 30.days, size: 1_000_000, api: true, private: true,
                                          name: 'Agency'
        add_plan :agency_v2, 75.0, 0.33333333, ttl: 30.days, size: 1_000_000, api: true, private: true,
                                               name: 'Agency'
        # Hacker News special
        add_plan :personal_hn, 0, 0, ttl: 14.days, size: 1_000_000, api: true, name: 'HN Special'
        # Reddit special
        add_plan :personal_reddit, 0, 0, ttl: 14.days, size: 1_000_000, api: true, name: 'Reddit Special'
        # Added 2011-12-24s
        add_plan :basic_v1, 10.0, 0.5, ttl: 30.days, size: 1_000_000, api: true, name: 'Basic'
        add_plan :individual_v1, 0, 0, ttl: 14.days, size: 1_000_000, api: true, name: 'Individual'
        # Added 2012-01-27
        add_plan :nonprofit_v1, 0, 0, ttl: 30.days, size: 1_000_000, api: true, cname: true,
                                      name: 'Non Profit'
      end
    end
    attr_reader :planid, :price, :discount, :options

    def initialize(planid, price, discount, options = {})
      @planid = self.class.normalize(planid)
      @price = price
      @discount = discount
      @options = options
    end

    def calculated_price
      (price * (1 - discount)).to_i
    end

    def paid?
      !free?
    end

    def free?
      calculated_price.zero?
    end
  end

end
