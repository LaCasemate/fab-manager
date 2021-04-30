# frozen_string_literal: true

require 'test_helper'

class Subscriptions::RenewAsAdminTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin successfully renew a subscription before it has ended' do
    user = User.find_by(username: 'kdumas')
    plan = Plan.find_by(base_name: 'Mensuel tarif réduit')

    VCR.use_cassette('subscriptions_admin_renew_success') do
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

    # Check that the user has the correct subscription
    assert_not_nil user.subscription, "user's subscription was not found"
    assert_not_nil user.subscribed_plan, "user's subscribed plan was not found"
    assert_not_nil user.subscription.plan, "user's subscribed plan was not found"
    assert_equal plan.id, user.subscription.plan_id, "user's plan does not match"

    # Check the expiration date
    assert_equal (user.subscription.created_at + plan.interval_count.send(plan.interval)).iso8601,
                 subscription[:expired_at],
                 'subscription expiration date does not match'

    # Check the subscription was correctly saved
    assert_equal 2, user.subscriptions.count

    # Check that the training credits were set correctly
    assert_empty user.training_credits, 'training credits were not reset'
    assert_equal user.subscription.plan.training_credit_nb, plan.training_credit_nb, 'trainings credits were not allocated'

    # Check that the user benefit from prices of his plan
    printer = Machine.find_by(slug: 'imprimante-3d')
    assert_equal 10,
                 (printer.prices.find_by(group_id: user.group_id, plan_id: user.subscription.plan_id).amount / 100),
                 'machine hourly price does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by_name('notify_member_subscribed_plan'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'

    # Check generated invoice
    invoice = Invoice.find_by(invoiced_type: 'Subscription', invoiced_id: subscription[:id])
    assert_invoice_pdf invoice
    assert_equal plan.amount, invoice.total, 'Invoice total price does not match the bought subscription'
  end

  test 'admin successfully offer free days' do
    user = User.find_by(username: 'pdurand')
    subscription = user.subscription.clone
    new_date = (1.month.from_now - 4.days).utc

    VCR.use_cassette('subscriptions_admin_offer_free_days') do
      put "/api/subscriptions/#{subscription.id}",
          params: {
            subscription: {
              expired_at: new_date.strftime('%Y-%m-%d %H:%M:%S.%9N Z'),
              free: true
            }
          }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Check that the subscribed plan was not altered
    res_subscription = json_response(response.body)
    assert_equal subscription.id, res_subscription[:id], 'subscription id has changed'
    assert_equal subscription.plan_id, res_subscription[:plan_id], 'subscribed plan does not match'
    assert_dates_equal new_date, res_subscription[:expired_at], 'subscription end date was not updated'

    # Check the subscription was correctly saved
    assert_equal 1, user.subscriptions.count

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by_name('notify_member_subscription_extended'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_nil notification, 'user notification was not created'
    assert_not_nil notification.get_meta_data(:free_days),
                   "notification didn't says to the user that her extent was for free"
    assert_equal user.id, notification.receiver_id, 'wrong user notified'
  end

  test 'admin successfully extends a subscription' do
    user = User.find_by(username: 'pdurand')
    subscription = user.subscription.clone
    new_date = (1.month.from_now - 4.days).utc

    VCR.use_cassette('subscriptions_admin_extends_subscription') do
      put "/api/subscriptions/#{subscription.id}",
          params: {
            subscription: {
              expired_at: new_date.strftime('%Y-%m-%d %H:%M:%S.%9N Z')
            }
          }.to_json, headers: default_headers
    end

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Check that the subscribed plan is still the same
    res_subscription = json_response(response.body)
    assert_equal subscription.plan_id, res_subscription[:plan_id], 'subscribed plan does not match'

    # Check the subscription was correctly saved
    assert_equal 2, user.subscriptions.count

    # Check that the subscription is new
    assert_not_equal subscription.id, res_subscription[:id], 'subscription id has not changed'
    assert_dates_equal new_date, res_subscription[:expired_at], 'subscription end date does not match'

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by_name('notify_member_subscribed_plan'),
      attached_object_type: 'Subscription',
      attached_object_id: subscription[:id]
    )
    assert_not_nil notification, 'user notification was not created'
    assert_equal user.id, notification.receiver_id, 'wrong user notified'
  end
end
