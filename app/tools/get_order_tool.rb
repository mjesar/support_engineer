class GetOrderTool < RubyLLM::Tool
  description "Looks up one order by its id. Returns its status, purchase, shipping and delivery dates, " \
              "and the items with name, category, price and whether they are final sale."

  parameter :order_id, type: :integer, description: "The order id the customer gives, for example 1042"

  def execute(order_id:)
    GetOrder.call(order_id)
  end
end
