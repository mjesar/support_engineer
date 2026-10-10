class GetShipment
  def self.call(order_id)
    new(order_id).call
  end

  def initialize(order_id)
    @order_id = order_id
  end

  def call
    return { error: "Order #{@order_id} not found" } unless order
    return { error: "Order #{@order_id} has no shipment" } unless order.shipment

    shipment_details
  end

  private

  def order
    @order ||= Order.includes(:shipment).find_by(id: @order_id)
  end

  # Named fields only: the model sees exactly what is listed here, nothing else.
  def shipment_details
    shipment = order.shipment

    {
      status: shipment.status,
      carrier: shipment.carrier,
      tracking_number: shipment.tracking_number,
      last_known_location: shipment.last_known_location,
      last_scan_at: shipment.last_scan_at
    }
  end
end
