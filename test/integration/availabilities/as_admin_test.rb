# frozen_string_literal: true

require 'test_helper'

module Availabilities
  class AsAdminTest < ActionDispatch::IntegrationTest
    setup do
      admin = User.with_role(:admin).first
      login_as(admin, scope: :user)
    end

    test 'return availability by id' do
      a = Availability.take

      get "/api/availabilities/#{a.id}"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime[:json], response.content_type

      # Check the correct availability was returned
      availability = json_response(response.body)
      assert_equal a.id, availability[:id], 'availability id does not match'
    end

    test 'get machine availabilities as admin' do
      m = Machine.find_by(slug: 'decoupeuse-vinyle')

      get "/api/availabilities/machines/#{m.id}"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime[:json], response.content_type

      # Check the correct availabilities was returned
      availabilities = json_response(response.body)
      assert_not_empty availabilities, 'no availabilities were found'
      assert_not_nil availabilities[0], 'first availability was unexpectedly nil'
      assert_not_nil availabilities[0][:machine], "first availability's machine was unexpectedly nil"
      assert_equal m.id, availabilities[0][:machine][:id], "first availability's machine does not match the required machine"

      # as admin, we can get availabilities from the past (from v4.3.0)
    end

    test 'get calendar availabilities without spaces' do
      # disable spaces in application
      Setting.set('spaces_module', false)

      # this simulates a fullCalendar (v2) call
      start_date = DateTime.current.utc.strftime('%Y-%m-%d')
      end_date = 7.days.from_now.utc.strftime('%Y-%m-%d')
      tz = Time.zone.tzinfo.name
      get "/api/availabilities?start=#{start_date}&end=#{end_date}&timezone=#{tz}&_=1487169767960"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime[:json], response.content_type

      # Check the correct availabilities was returned
      availabilities = json_response(response.body)
      assert_not_empty availabilities, 'no availabilities were found'
      assert_not_nil availabilities[0], 'first availability was unexpectedly nil'

      assert_not availabilities.map { |a| a[:available_type] }.include?('space'), 'unexpected space availability instead that it was disabled'

      # re-enable spaces
      Setting.set('spaces_module', true)
    end

    test 'get calendar availabilities with spaces' do
      # this simulates a fullCalendar (v2) call
      start_date = DateTime.current.utc.strftime('%Y-%m-%d')
      end_date = 7.days.from_now.utc.strftime('%Y-%m-%d')
      tz = Time.zone.tzinfo.name
      get "/api/availabilities?start=#{start_date}&end=#{end_date}&timezone=#{tz}&_=1487169767960"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime[:json], response.content_type

      # Check the correct availabilities was returned
      availabilities = json_response(response.body)
      assert_not_empty availabilities, 'no availabilities were found'
      assert_not_nil availabilities[0], 'first availability was unexpectedly nil'

      assert availabilities.map { |a| a[:available_type] }.include?('space'), 'space availability not found instead that it was enabled'
    end

    test 'create availabilities' do
      date = DateTime.current.change(hour: 8, min: 0, sec: 0)
      post '/api/availabilities',
           params: {
             availability: {
               start_at: date.iso8601,
               end_at: (date + 6.hours).iso8601,
               available_type: 'machines',
               tag_ids: [],
               is_recurrent: true,
               period: 'week',
               nb_periods: 1,
               end_date: (date + 2.weeks).end_of_day.iso8601,
               slot_duration: 90,
               machine_ids: [2, 3, 5],
               occurrences: [
                 { start_at: date.iso8601, end_at: (date + 6.hours).iso8601 },
                 { start_at: (date + 1.week).iso8601, end_at: (date + 1.week + 6.hours).iso8601 },
                 { start_at: (date + 2.weeks).iso8601, end_at: (date + 2.weeks + 6.hours).iso8601 }
               ],
               plan_ids: [1]
             }
           }

      # Check response format & status
      assert_equal 201, response.status
      assert_equal Mime[:json], response.content_type

      # Check the id
      availability = json_response(response.body)
      assert_not_nil availability[:id], 'availability ID was unexpectedly nil'

      # Check the slots
      assert_equal (availability[:start_at].to_datetime + availability[:slot_duration].minutes * 4).iso8601,
                   availability[:end_at],
                   'expected end_at = start_at + 4 slots of 90 minutes'

      # Check the recurrence
      assert_equal (availability[:start_at].to_datetime + 2.weeks).to_date,
                   availability[:end_date].to_datetime.utc.to_date,
                   'expected end_date = start_at + 2 weeks'
    end
  end
end
