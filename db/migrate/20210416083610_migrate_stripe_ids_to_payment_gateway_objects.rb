# frozen_string_literal: true

require 'integrity/archive_helper'

# From this migration we remove the deep association between Stripe and Fab-manager
# and save the data related to the payment gateway in a generic way
class MigrateStripeIdsToPaymentGatewayObjects < ActiveRecord::Migration[5.2]
  def up
    # first, check the footprints
    Integrity::ArchiveHelper.check_footprints

    # if everything is ok, proceed with migration
    # remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    ## INVOICES
    puts 'Migrating invoices...'
    Invoice.order(:id).all.each do |i|
      if i.stp_invoice_id
        PaymentGatewayObject.create!(
          item: i,
          gateway_object_id: i.stp_invoice_id,
          gateway_object_type: 'Stripe::Invoice'
        )
        i.update(payment_method: 'card')
      elsif i.stp_payment_intent_id
        PaymentGatewayObject.create!(
          item: i,
          gateway_object_id: i.stp_payment_intent_id,
          gateway_object_type: 'Stripe::PaymentIntent'
        )
        i.update(payment_method: 'card')
      end
    end
    remove_column :invoices, :stp_invoice_id
    remove_column :invoices, :stp_payment_intent_id

    ## INVOICE ITEMS
    puts 'Migrating invoices items...'
    InvoiceItem.order(:id).all.each do |ii|
      next unless ii.stp_invoice_item_id

      is_subscription = /^sub_/.match? ii.stp_invoice_item_id
      PaymentGatewayObject.create!(
        item: ii,
        gateway_object_id: ii.stp_invoice_item_id,
        gateway_object_type: is_subscription ? 'Stripe::Subscription' : 'Stripe::InvoiceItem'
      )
    end
    remove_column :invoice_items, :stp_invoice_item_id

    ## SUBSCRIPTIONS
    # stp_subscription_id is not used anymore.
    # It is an artifact of the very firsts releases of Fab-manager when we were creating a Stripe::Subscription for each new subscription.
    # This was intended to automatically renew all subscriptions, but this feature was not acclaimed by the users.
    # To fix it, we made a workaround to automatically cancel the subscription, just after it was took.
    # This workaround was kept in the code until v4.1.0 (SCA release), when we removed this whole pointless feature.
    # We keep this data for accounting integrity but we don't know it is gonna be useful again in the future
    puts 'Migrating subscriptions...'
    Subscription.order(:id).all.each do |sub|
      next unless sub.stp_subscription_id

      PaymentGatewayObject.create!(
        item: sub,
        gateway_object_id: sub.stp_subscription_id,
        gateway_object_type: 'Stripe::Subscription'
      )
    end
    remove_column :subscriptions, :stp_subscription_id

    ## PAYMENT SCHEDULES
    puts 'Migrating payment schedules...'
    PaymentSchedule.order(:id).all.each do |ps|
      if ps.stp_subscription_id
        PaymentGatewayObject.create!(
          item: ps,
          gateway_object_id: ps.stp_subscription_id,
          gateway_object_type: 'Stripe::Subscription'
        )
      end
      next unless ps.stp_setup_intent_id

      PaymentGatewayObject.create!(
        item: ps,
        gateway_object_id: ps.stp_setup_intent_id,
        gateway_object_type: 'Stripe::SetupIntent'
      )
      ps.update(payment_method: 'card')
    end
    remove_column :payment_schedules, :stp_subscription_id
    remove_column :payment_schedules, :stp_setup_intent_id

    ## PAYMENT SCHEDULE ITEMS
    puts 'Migrating payment schedule items...'
    PaymentScheduleItem.order(:id).all.each do |psi|
      next unless psi.stp_invoice_id

      PaymentGatewayObject.create!(
        item: psi,
        gateway_object_id: psi.stp_invoice_id,
        gateway_object_type: 'Stripe::Invoice'
      )
    end
    remove_column :payment_schedule_items, :stp_invoice_id

    ## PLANS, MACHINES, SPACES, TRAININGS
    puts 'Migrating stp_product_ids...'
    [Plan, Machine, Space, Training].each do |klass|
      klass.order(:id).all.each do |item|
        next unless item.stp_product_id

        PaymentGatewayObject.create!(
          item: item,
          gateway_object_id: item.stp_product_id,
          gateway_object_type: 'Stripe::Product'
        )
      end
      remove_column klass.arel_table.name, :stp_product_id
    end

    ## USERS
    puts 'Migrating users...'
    User.order(:id).all.each do |u|
      next unless u.stp_customer_id

      PaymentGatewayObject.create!(
        item: u,
        gateway_object_id: u.stp_customer_id,
        gateway_object_type: 'Stripe::Customer'
      )
    end
    remove_column :users, :stp_customer_id

    # chain all records
    puts 'Chaining all record. This may take a while...'
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)
    PaymentScheduleItem.order(:id).all.each(&:chain_record)
    PaymentSchedule.order(:id).all.each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end

  def down
    # here we don't check footprints to save processing time and because this is pointless when reverting the migrations

    # remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    # reset parameters
    add_column :invoices, :stp_invoice_id, :string
    add_column :invoices, :stp_payment_intent_id, :string
    add_column :invoice_items, :stp_invoice_item_id, :string
    add_column :subscriptions, :stp_subscription_id, :string
    add_column :payment_schedules, :stp_subscription_id, :string
    add_column :payment_schedules, :stp_setup_intent_id, :string
    add_column :payment_schedule_items, :stp_invoice_id, :string
    add_column :users, :stp_customer_id, :string
    [Plan, Machine, Space, Training].each do |klass|
      add_column klass.arel_table.name, :stp_product_id, :string
    end
    PaymentGatewayObject.order(:id).all.each do |pgo|
      attr = case pgo.gateway_object_type
             when 'Stripe::Product'
               'stp_product_id'
             when 'Stripe::Invoice'
               'stp_invoice_id'
             when 'Stripe::SetupIntent'
               'stp_setup_intent_id'
             when 'Stripe::Subscription'
               pgo.item_type == InvoiceItem.name ? 'stp_invoice_item_id' : 'stp_subscription_id'
             when 'Stripe::InvoiceItem'
               'stp_invoice_item_id'
             when 'Stripe::PaymentIntent'
               'stp_payment_intent_id'
             when 'Stripe::Customer'
               'stp_customer_id'
             else
               puts "Unknown gateway_object_type #{pgo.gateway_object_type}, ignoring..."
               nil
             end
      if attr
        item = pgo.item
        item.update_column(attr, pgo.gateway_object_id)
      end
    end

    # chain all records
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)
    PaymentScheduleItem.order(:id).all.each(&:chain_record)
    PaymentSchedule.order(:id).all.each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end
end
