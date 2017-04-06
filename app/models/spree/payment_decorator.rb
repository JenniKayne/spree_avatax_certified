Spree::Payment.class_eval do
  self.state_machine.before_transition to: :completed, do: :avalara_finalize
  self.state_machine.before_transition to: :processing, do: :avalara_update
  self.state_machine.after_transition to: :void, do: :cancel_avalara

  def avalara_tax_enabled?
    Spree::Config.avatax_tax_calculation
  end

  def cancel_avalara
    order.avalara_transaction.cancel_order unless order.avalara_transaction.nil?
  end

  def avalara_update
    # without reload order was charged without tax amount
    order.reload

    if self.amount != order.total
      self.update_attributes(amount: order.total)
    end
  end

  def avalara_finalize
    return unless avalara_tax_enabled?

    if self.amount != order.total
      self.update_attributes(amount: order.total)
    end

    order.avalara_capture_finalize
  end
end
