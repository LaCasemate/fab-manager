# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::AsUserTest < ActionDispatch::IntegrationTest
  test 'reserve event with many prices and payment means and VAT' do
    vlonchamp = User.find_by(username: 'vlonchamp')
    login_as(vlonchamp, scope: :user)

    radio = Event.find(4)
    availability = radio.availability

    reservations_count = Reservation.count
    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    # Enable the VAT at 19.6%
    vat_active = Setting.find_by(name: 'invoice_VAT-active')
    vat_active.value = 'true'
    vat_active.save!

    vat_rate = Setting.find_by(name: 'invoice_VAT-rate')
    vat_rate.value = '19.6'
    vat_rate.save!

    # Reserve the 'radio' event
    VCR.use_cassette('reserve_event_with_many_prices_and_payment_means') do
      post '/api/stripe/confirm_payment',
           params: {
             payment_method_id: stripe_payment_method,
             cart_items: {
               customer_id: User.find_by(username: 'vlonchamp').id,
               reservation: {
                 reservable_id: radio.id,
                 reservable_type: 'Event',
                 nb_reserve_places: 2,
                 slots_attributes: [
                   {
                     start_at: availability.start_at,
                     end_at: availability.end_at,
                     availability_id: availability.id,
                     offered: false
                   }
                 ],
                 tickets_attributes: [
                   {
                     event_price_category_id: radio.event_price_categories[0].id,
                     booked: 2
                   },
                   {
                     event_price_category_id: radio.event_price_categories[1].id,
                     booked: 2
                   }
                 ]
               },
               coupon_code: 'SUNNYFABLAB'
             }
           }.to_json, headers: default_headers
    end

    vlonchamp.wallet.reload

    # general assertions
    assert_equal 201, response.status
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count

    # reservation assertions
    reservation = Reservation.last

    assert reservation.invoice
    assert_equal 1, reservation.invoice.invoice_items.count

    # invoice assertions
    invoice = reservation.invoice

    refute invoice.payment_gateway_object.blank?
    refute invoice.total.blank?
    assert_equal 43_350, invoice.total # total minus coupon

    # invoice_items assertions
    ## reservation
    reservation_item = invoice.invoice_items.first

    assert_not_nil reservation_item
    assert_equal 51_000, reservation_item.amount # full total

    # invoice assertions
    invoice = Invoice.find_by(invoiced: reservation)
    assert_invoice_pdf invoice

    VCR.use_cassette('reserve_event_with_many_prices_and_payment_means_retrieve_invoice_from_stripe') do
      stp_intent = invoice.payment_gateway_object.gateway_object.retrieve
      assert_equal stp_intent.amount, (invoice.total - invoice.wallet_amount) # total minus coupon minus wallet = amount really paid by the user
    end

    # wallet assertions
    assert_equal vlonchamp.wallet.amount, 0
    assert_equal vlonchamp.wallet.wallet_transactions.count, 2
    transaction = vlonchamp.wallet.wallet_transactions.last
    assert_equal transaction.transaction_type, 'debit'
    assert_equal transaction.amount, 10
    assert_equal transaction.amount, invoice.wallet_amount / 100.0

    # notifications
    assert_not_empty Notification.where(attached_object: reservation)
    assert_not_empty Notification.where(attached_object: invoice)
  end
end
