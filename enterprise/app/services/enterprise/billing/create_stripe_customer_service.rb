class Enterprise::Billing::CreateStripeCustomerService
  include BillingHelper

  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    # Self-serve Stripe subscriptions are disabled for this installation.
    # Grant plan features and limits from Super Admin instead.
    false
  end
end
