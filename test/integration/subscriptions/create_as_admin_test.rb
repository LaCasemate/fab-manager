# frozen_string_literal: true

require 'test_helper'

class Subscriptions::CreateAsAdminTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin successfully takes a subscription for a user' do
    user = User.find_by(username: 'jdupond')
    plan = Plan.find_by(group_id: user.group.id, type: 'Plan', base_name: 'Mensuel')

    VCR.use_cassette('subscriptions_admin_create_success') do
      post '/api/subscriptions',
           params: {
             customer_id: user.id,
             subscription: {
               plan_id: plan.id
             }
           }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Check the correct plan was subscribed
    subscription = json_response(response.body)
    assert_equal plan.id, subscription[:plan_id], 'subscribed plan does not match'

    # Check that the user has only one subscription
    assert_equal 1, user.subscriptions.count

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"

    # Check that the training credits were set correctly
    assert_empty user.training_credits, 'training credits were not reset'
    assert_equal user.subscription.plan.training_credit_nb, plan.training_credit_nb, 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 15, (printer.prices.find_by(group_id: user.group_id, plan_id: user.subscription.plan_id).amount / 100.00), 'machine hourly price does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(notification_type_id: NotificationType.find_by_name('notify_member_subscribed_plan'), attached_object_type: 'Subscription', attached_object_id: subscription[:id])
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'

    # Check generated invoice
    invoice = Invoice.find_by(invoiced_type: 'Subscription', invoiced_id: subscription[:id])
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'
  end

  test 'admin takes a subscription with a payment schedule' do
    user = User.find_by(username: 'jdupond')
    plan = Plan.find_by(group_id: user.group.id, type: 'Plan', base_name: 'Abonnement mensualisable')
    invoice_count = Invoice.count
    payment_schedule_count = PaymentSchedule.count
    payment_schedule_items_count = PaymentScheduleItem.count

    VCR.use_cassette('subscriptions_admin_create_with_payment_schedule') do
      get "/api/stripe/setup_intent/#{user.id}"

      # Check response format & status
      assert_equal 200, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the response
      setup_intent = json_response(response.body)
      assert_not_nil setup_intent[:client_secret]
      assert_not_nil setup_intent[:id]
      assert_match /^#{setup_intent[:id]}_secret_/, setup_intent[:client_secret]

      # Confirm the intent
      stripe_res = Stripe::SetupIntent.confirm(
        setup_intent[:id],
        { payment_method: stripe_payment_method },
        { api_key: Setting.get('stripe_secret_key') }
      )

      # check the confirmation
      assert_equal setup_intent[:id], stripe_res.id
      assert_equal 'succeeded', stripe_res.status
      assert_equal 'off_session', stripe_res.usage


      post '/api/stripe/confirm_payment_schedule',
           params: {
             setup_intent_id: setup_intent[:id],
             cart_items: {
               customer_id: user.id,
               subscription: {
                 plan_id: plan.id,
                 payment_schedule: true,
                 payment_method: 'stripe'
               }
             }
           }.to_json, headers: default_headers
    end

    # Check generalities
    assert_equal 201, response.status, response.body
    assert_equal Mime[:json], response.content_type
    assert_equal invoice_count, Invoice.count, "an invoice was generated but it shouldn't"
    assert_equal payment_schedule_count + 1, PaymentSchedule.count, 'missing the payment schedule'
    assert_equal payment_schedule_items_count + 12, PaymentScheduleItem.count, 'missing some payment schedule items'

    # Check the correct plan was subscribed
    subscription = json_response(response.body)
    assert_equal plan.id, subscription[:plan_id], 'subscribed plan does not match'

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"
  end
end
