class GetShipmentTool < RubyLLM::Tool
  description "Looks up where the package of an order is. Takes the order id, not a shipment id. " \
              "Returns the shipment status, carrier, tracking number, last known location and last scan time. " \
              "Returns an error if the order has not shipped yet."

  parameter :order_id, type: :integer, description: "The order id the customer gives, for example 1042"

  def execute(order_id:)
    GetShipment.call(order_id)
  end
end
