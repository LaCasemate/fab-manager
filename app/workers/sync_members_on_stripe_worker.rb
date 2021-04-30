# frozen_string_literal: true

# This worker perform various requests to the Stripe API (payment service)
class SyncMembersOnStripeWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, on_conflict: :reject, queue: :stripe

  def perform(notify_user_id = nil)
    logger.debug 'We create all non-existing customers on stripe. This may take a while...'
    total = User.online_payers.count
    User.online_payers.each_with_index do |member, index|
      logger.debug "#{index} / #{total}"
      begin
        stp_customer = member.payment_gateway_objects.gateway_object.retrieve
        StripeWorker.new.create_stripe_customer(member.id) if stp_customer.nil? || stp_customer[:deleted]
      rescue Stripe::InvalidRequestError
        StripeWorker.new.create_stripe_customer(member.id)
      end
    end
    logger.debug 'Sync is done'
    return unless notify_user_id

    logger.debug "Notify user #{notify_user_id}"
    user = User.find(notify_user_id)
    NotificationCenter.call type: :notify_admin_members_stripe_sync,
                            receiver: user,
                            attached_object: user
  end
end
