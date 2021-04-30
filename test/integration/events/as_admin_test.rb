# frozen_string_literal: true

module Events
  class AsAdminTest < ActionDispatch::IntegrationTest
    setup do
      admin = User.with_role(:admin).first
      login_as(admin, scope: :user)
    end

    test 'creation modification reservation and re-modification scenario' do
      # First, we create a new event
      post '/api/events',
           params: {
             event: {
               title: 'OpenLab discovery day',
               description: 'A day to discover the Fablab and try its machines and possibilities.',
               start_date: 1.week.from_now.utc,
               start_time: 1.week.from_now.utc.change(hour: 16),
               end_date: 1.week.from_now.utc,
               end_time: 1.week.from_now.utc.change(hour: 20),
               category_id: Category.first.id,
               amount: 0
             }
           }.to_json,
           headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the event was created correctly
      event = json_response(response.body)
      e = Event.where(id: event[:id]).first
      assert_not_nil e, 'Event was not created in database'

      # Check the remaining free places are not defined
      assert_nil e.nb_free_places, "Free places shouldn't be defined"

      # Then, modify the event to set a nb of places
      put "/api/events/#{e.id}",
          params: {
            event: {
              title: 'OpenLab discovery day',
              description: 'A day to discover the Fablab and try its machines and possibilities.',
              start_date: 1.week.from_now.utc,
              start_time: 1.week.from_now.utc.change(hour: 16),
              end_date: 1.week.from_now.utc,
              end_time: 1.week.from_now.utc.change(hour: 20),
              category_id: Category.first.id,
              amount: 0,
              nb_total_places: 10
            }
          }

      # Check response format & status
      assert_equal 200, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the places numbers were updated successfully
      e = Event.where(id: event[:id]).first
      assert_equal 10, e.nb_total_places, 'Total number of places was not updated'
      assert_equal 10, e.nb_free_places, 'Number of free places was not updated'

      # Now, let's make a reservation on this event
      post '/api/reservations',
           params: {
             customer_id: User.find_by(username: 'pdurand').id,
             reservation: {
               reservable_id: e.id,
               reservable_type: 'Event',
               nb_reserve_places: 2,
               slots_attributes: [
                 {
                   start_at: e.availability.start_at,
                   end_at: e.availability.end_at,
                   availability_id: e.availability.id,
                   offered: false
                 }
               ]
             }
           }.to_json,
           headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the remaining places were updated successfully
      e = Event.where(id: event[:id]).first
      assert_equal 8, e.nb_free_places, 'Number of free places was not updated'

      # Finally, modify the event to add some places
      put "/api/events/#{e.id}",
          params: {
            event: {
              title: 'OpenLab discovery day',
              description: 'A day to discover the Fablab and try its machines and possibilities.',
              start_date: 1.week.from_now.utc,
              start_time: 1.week.from_now.utc.change(hour: 16),
              end_date: 1.week.from_now.utc,
              end_time: 1.week.from_now.utc.change(hour: 20),
              category_id: Category.first.id,
              amount: 0,
              nb_total_places: 20
            }
          }

      # Check response format & status
      assert_equal 200, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the places numbers were updated successfully
      e = Event.where(id: event[:id]).first
      assert_equal 20, e.nb_total_places, 'Total number of places was not updated'
      assert_equal 18, e.nb_free_places, 'Number of free places was not updated'
    end

    test 'create event with custom price and reserve it with success' do
      price_category = PriceCategory.first

      # First, we create a new event
      post '/api/events',
           params: {
             event: {
               title: 'Electronics initiation',
               description: 'A workshop about electronics and the abilities to create robots.',
               start_date: 1.week.from_now.utc + 2.days,
               start_time: 1.week.from_now.utc.change(hour: 18) + 2.days,
               end_date: 1.week.from_now.utc + 2.days,
               end_time: 1.week.from_now.utc.change(hour: 22) + 2.days,
               category_id: Category.last.id,
               amount: 20,
               nb_total_places: 10,
               event_price_categories_attributes: [
                 {
                   price_category_id: price_category.id.to_s,
                   amount: 16.to_s
                 }
               ]
             }
           }.to_json,
           headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the event was created correctly
      event = json_response(response.body)
      e = Event.where(id: event[:id]).first
      assert_not_nil e, 'Event was not created in database'

      # Check the places numbers were set successfully
      e = Event.where(id: event[:id]).first
      assert_equal 10, e.nb_total_places, 'Total number of places was not updated'
      assert_equal 10, e.nb_free_places, 'Number of free places was not updated'

      # Now, let's make a reservation on this event
      post '/api/reservations',
           params: {
             customer_id: User.find_by(username: 'lseguin').id,
             reservation: {
               reservable_id: e.id,
               reservable_type: 'Event',
               nb_reserve_places: 4,
               slots_attributes: [
                 {
                   start_at: e.availability.start_at,
                   end_at: e.availability.end_at,
                   availability_id: e.availability.id,
                   offered: false
                 }
               ],
               tickets_attributes: [
                 {
                   event_price_category_id: e.event_price_categories.first.id,
                   booked: 4
                 }
               ]
             }
           }.to_json,
           headers: default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_equal Mime[:json], response.content_type

      # Check the reservation match the required event
      reservation = json_response(response.body)
      r = Reservation.find(reservation[:id])

      assert_equal e.id, r.reservable_id
      assert_equal 'Event', r.reservable_type

      # Check the remaining places were updated successfully
      e = Event.where(id: event[:id]).first
      assert_equal 2, e.nb_free_places, 'Number of free places was not updated'

      # Check the resulting invoice generation and it has right price
      assert_invoice_pdf r.invoice
      assert_equal (4 * 20) + (4 * 16), r.invoice.total / 100.0
    end
  end
end
