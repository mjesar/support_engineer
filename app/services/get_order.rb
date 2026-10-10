class GetOrder
  def self.call(order_id)
    new(order_id).call
  end

  def initialize(order_id)
    @order_id = order_id
  end

  def call
    return { error: "Order #{@order_id} not found" } unless order

    order_details
  end

  private

  def order
    @order ||= Order.includes(order_items: :product).find_by(id: @order_id)
  end

  # Named fields only: the model sees exactly what is listed here, nothing else.
  def order_details
    {
      id: order.id,
      status: order.status,
      purchased_at: order.purchased_at,
      shipped_at: order.shipped_at,
      delivered_at: order.delivered_at,
      estimated_delivery_at: order.estimated_delivery_at,
      items: order.order_items.map { |item| item_details(item) }
    }
  end

  def item_details(item)
    {
      name: item.product.name,
      category: item.product.category,
      price: item.price.to_f,
      final_sale: item.product.final_sale
    }
  end
end
