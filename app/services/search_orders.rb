class SearchOrders
  # Small on purpose: the model's context and the Groq token limit are the real ceiling.
  LIMIT = 10

  def self.call(customer_id:, status: nil)
    new(customer_id:, status:).call
  end

  def initialize(customer_id:, status: nil)
    @customer_id = customer_id
    @status = status
  end

  def call
    return { error: "Customer #{@customer_id} not found" } unless Customer.exists?(@customer_id)

    { total: orders.count, orders: orders.limit(LIMIT).map { |order| order_summary(order) } }
  end

  private

  # Always scoped to one customer, so a search can never list the whole table.
  def orders
    scope = Order.where(customer_id: @customer_id).order(purchased_at: :desc)
    scope = scope.where(status: @status) if @status.present?
    scope
  end

  def order_summary(order)
    {
      id: order.id,
      status: order.status,
      purchased_at: order.purchased_at,
      estimated_delivery_at: order.estimated_delivery_at
    }
  end
end
