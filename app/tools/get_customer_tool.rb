class GetCustomerTool < RubyLLM::Tool
  description "Looks up a customer by id. Returns their name, city and state. " \
              "It does not return contact details or orders; use search_orders to list a customer's orders."

  parameter :customer_id, type: :integer, description: "The customer id, for example 68585"

  def execute(customer_id:)
    GetCustomer.call(customer_id)
  end
end
