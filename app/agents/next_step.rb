class NextStep
  STEPS = {
    "order_status" => :look_up_order,
    "refund" => :check_refund_policy,
    "complaint" => :escalate_to_human,
    "other" => :answer_directly
  }.freeze

  # fetch raises on an unknown intent: the schema only allows these four, so
  # anything else is a bug to see, not a case to guess a default for.
  def self.for(intent)
    STEPS.fetch(intent)
  end
end
