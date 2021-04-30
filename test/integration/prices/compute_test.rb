# frozen_string_literal: true

module Prices
  class AsAdminTest < ActionDispatch::IntegrationTest
    setup do
      admin = User.with_role(:admin).first
      login_as(admin, scope: :user)
    end

    test 'compute price for a simple training' do
      user = User.find_by(username: 'jdupond')
      availability = Availability.find(2)
      printer_training = availability.trainings.first

      post '/api/prices/compute',
           params: {
             customer_id: user.id,
             reservation: {
               reservable_id: printer_training.id,
               reservable_type: printer_training.class.name,
               slots_attributes: [
                 {
                   availability_id: availability.id,
                   end_at: availability.end_at,
                   offered: false,
                   start_at: availability.start_at
                 }
               ]
             }
           }.to_json,
           headers: default_headers

      # Check response format & status
      assert_equal 200, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the price was computed correctly
      price = json_response(response.body)
      assert_equal (printer_training.trainings_pricings.where(group_id: user.group_id).first.amount / 100.0),
                   price[:price],
                   'Computed price did not match training price'
    end

    test 'compute price for a machine reservation with an offered slot and a subscription' do
      user = User.find_by(username: 'jdupond')
      availability = Availability.find(3)
      laser = availability.machines.where(id: 1).first
      plan = Plan.where(group_id: user.group_id, interval: 'month').first

      post '/api/prices/compute',
           params: {
             customer_id: user.id,
             reservation: {
               reservable_id: laser.id,
               reservable_type: laser.class.name,
               slots_attributes: [
                 {
                   availability_id: availability.id,
                   end_at: (availability.start_at + 1.hour).strftime('%Y-%m-%d %H:%M:%S.%9N Z'),
                   offered: true,
                   start_at: availability.start_at.strftime('%Y-%m-%d %H:%M:%S.%9N Z')
                 },
                 {
                   availability_id: availability.id,
                   end_at: (availability.start_at + 2.hour).strftime('%Y-%m-%d %H:%M:%S.%9N Z'),
                   offered: false,
                   start_at: (availability.start_at + 1.hour).strftime('%Y-%m-%d %H:%M:%S.%9N Z')
                 }
               ]
             },
             subscription: {
               plan_id: plan.id
             }
           }.to_json,
           headers: default_headers

      # Check response format & status
      assert_equal 200, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the event was created correctly
      price = json_response(response.body)
      assert_equal ((laser.prices.where(group_id: user.group_id, plan_id: plan.id).first.amount + plan.amount) / 100.0),
                   price[:price],
                   'Computed price did not match machine + subscription price'
    end
  end
end
