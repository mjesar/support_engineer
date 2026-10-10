class SearchOrdersTool < RubyLLM::Tool
  description "Lists a customer's most recent orders, newest first, up to 10, with the real total count. " \
              "Each entry has the order id, status and dates. Use it when the customer does not know their " \
              "order id, then call get_order for the details of one order."

  parameter :customer_id, type: :integer, description: "The customer id, for example 68585"
  parameter :status, type: :string, required: false,
                     description: "Only orders with this status: created, approved, invoiced, processing, " \
                                  "shipped, delivered, canceled or unavailable"

  def execute(customer_id:, status: nil)
    SearchOrders.call(customer_id:, status:)
  end
end
