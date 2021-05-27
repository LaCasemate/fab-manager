# frozen_string_literal: true

require 'integrity/archive_helper'

# This take will ensure data integrity for invoices.
# A bug introduced with v4.3.0 has made invoices without saving the associated Reservation (Invoice.invoiced_id is null).
# This issue is concerning slots restricted to subscribers, when the restriction is manually overridden by an admin.
namespace :fablab do
  desc 'Remove the invoices w/o reservation or regenerate the reservation'
  task fix_invoices: :environment do |_task, _args|
    next unless Invoice.where(invoiced_id: nil).count.positive?

    include ActionView::Helpers::NumberHelper

    # check the footprints and save the archives
    Integrity::ArchiveHelper.check_footprints
    ActiveRecord::Base.transaction do
      periods = Integrity::ArchiveHelper.backup_and_remove_periods

      # fix invoices data
      Invoice.where(invoiced_id: nil).each do |invoice|
        ii = invoice.invoice_items.where(subscription_id: nil).first
        puts '=============================================='
        puts "Invoice #{invoice.id} (# #{invoice.reference})"
        puts "Total: #{number_to_currency(invoice.total / 100.0)}"
        puts "Subject: #{ii.description}."
        puts "Customer: #{invoice.invoicing_profile.full_name} (#{invoice.invoicing_profile.email})"
        puts "Operator: #{invoice.operator_profile&.user&.profile&.full_name} (#{invoice.operator_profile&.user&.email})"
        puts "Date: #{invoice.created_at}"

        print 'Delete [d], create the missing reservation [c] OR keep as error[e] ? > '
        confirm = STDIN.gets.chomp
        if confirm == 'd'
          puts "Destroying #{invoice.id}..."
          invoice.destroy
        elsif confirm == 'c'
          if invoice.invoiced_type != 'Reservation'
            STDERR.puts "WARNING: Invoice #{invoice.id} is about #{invoice.invoiced_type}. Please handle manually."
            STDERR.puts 'Ignoring...'
            next
          end

          reservable = find_reservable(ii)
          if reservable
            if reservable.is_a? Event
              STDERR.puts "WARNING: invoice #{invoice.id} is linked to Event #{reservable.id}. This is unsupported, please handle manually."
              STDERR.puts 'Ignoring...'
              next
            end
            reservation = ::Reservation.create!(
              reservable_id: reservable.id,
              reservable_type: reservable.class.name,
              slots_attributes: slots_attributes(invoice, reservable),
              statistic_profile_id: StatisticProfile.find_by(user: invoice.user).id
            )
            invoice.update_attributes(invoiced: reservation)
          else
            STDERR.puts "WARNING: Unable to guess the reservable for invoice #{invoice.id}, please handle manually."
            STDERR.puts 'Ignoring...'
          end
        elsif confirm == 'e'
          invoice.update_attributes(invoiced_type: 'Error')
        else
          puts "Operation #{confirm} unknown. Ignoring invoice #{invoice.id}..."
        end
      end

      # chain records
      puts 'Chaining all record. This may take a while...'
      InvoiceItem.order(:id).all.each(&:chain_record)
      Invoice.order(:id).all.each(&:chain_record)

      # re-create all archives from the memory dump
      Integrity::ArchiveHelper.restore_periods(periods)
    end
  end

  private

  def find_reservable(invoice_item)
    descr = /^([a-zA-Z\u00C0-\u017F]+\s+)+/.match(invoice_item.description)[0].strip[/(.*)\s/, 1]
    reservable = InvoiceItem.where('description LIKE ?', "#{descr}%")
                            .map(&:invoice)
                            .filter { |i| !i.invoiced_id.nil? }
                            .map(&:invoiced)
                            .map(&:reservable)
                            .first
    reservable ||= [Machine, Training, Space].map { |c| c.where('name LIKE ?', "#{descr}%") }
                                             .filter { |r| r.count.positive? }
                                             .first
                     &.first

    reservable || Event.where('title LIKE ?', "#{descr}%").first
  end

  def find_slots(invoice)
    invoice.invoice_items.map do |ii|
      description = ii.description
      # DateTime.parse only works with english dates, so translate the month name
      month_idx = I18n.t('date.month_names').find_index { |month| month && description.include?(month) }
      unless month_idx.nil?
        description.gsub!(/#{I18n.t('date.month_names')[month_idx]}/, I18n.t('date.month_names', locale: :en)[month_idx])
      end
      start = DateTime.parse(description)
      end_time = DateTime.parse(/- (.+)$/.match(description)[1])
      [start, DateTime.new(start.year, start.month, start.day, end_time.hour, end_time.min, end_time.sec, DateTime.current.zone)]
    end
  end

  def find_availability(reservable, slot)
    return if reservable.is_a? Event

    availability = reservable.availabilities.where('start_at <= ? AND end_at >= ?', slot[0], slot[1]).first
    unless availability
      STDERR.puts "WARNING: Unable to find an availability for #{reservable.class.name} #{reservable.id}, at #{slot[0]}, creating..."
      availability = reservable.availabilities.create!(start_at: slot[0], end_at: slot[1])
    end
    availability
  end

  def slots_attributes(invoice, reservable)
    find_slots(invoice).map do |slot|
      {
        start_at: slot[0],
        end_at: slot[1],
        availability_id: find_availability(reservable, slot)&.id,
        offered: invoice.total.zero?
      }
    end
  end
end
