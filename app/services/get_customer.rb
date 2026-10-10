class GetCustomer
  def self.call(customer_id)
    new(customer_id).call
  end

  def initialize(customer_id)
    @customer_id = customer_id
  end

  def call
    return { error: "Customer #{@customer_id} not found" } unless customer

    customer_details
  end

  private

  def customer
    @customer ||= Customer.find_by(id: @customer_id)
  end

  # Personal data is limited to what a support answer needs: no email, no Olist id.
  def customer_details
    {
      id: customer.id,
      name: customer.name,
      city: customer.city,
      state: customer.state
    }
  end
end
