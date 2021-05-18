# frozen_string_literal: true

# Accounting integrity verifications
module Integrity; end

# Provides various helpers methods for interacting with accounting archives
class Integrity::ArchiveHelper
  class << self

    ## Checks the validity of all closed periods and raise an error otherwise
    def check_footprints
      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Checking invoices footprints from #{last_period.end_at}. This may take a while..."
        Invoice.where('created_at > ?', last_period.end_at).order(:id).each do |i|
          next if i.check_footprint

          i.debug_footprint
          raise "Invalid footprint for invoice #{i.id}"
        end
      else
        puts 'Checking all invoices footprints. This may take a while...'
        Invoice.order(:id).all.each do |i|
          next if i.check_footprint

          i.debug_footprint
          raise "Invalid footprint for invoice #{i.id}"
        end
      end
    end

    # will return an array of hash containing the removed periods data
    def backup_and_remove_periods(range_start: nil, range_end: nil)
      range_periods = get_periods(range_start: range_start, range_end: range_end)
      return [] unless range_periods.count.positive?

      puts 'Removing accounting archives...'
      # 1. remove protection for AccountingPeriods
      execute("DROP RULE IF EXISTS accounting_periods_del_protect ON #{AccountingPeriod.arel_table.name};")
      # 2. backup AccountingPeriods in memory
      periods = []
      range_periods.each do |p|
        periods.push(
          start_at: p.start_at,
          end_at: p.end_at,
          closed_at: p.closed_at,
          closed_by: p.closed_by
        )
      end
      # 3. Delete periods from database
      range_periods.each do |ap|
        execute("DELETE FROM accounting_periods WHERE ID=#{ap.id};")
      end
      periods
    end

    def restore_periods(periods)
      return unless periods.size.positive?

      # 1. recreate AccountingPeriods
      puts 'Recreating accounting archives. This may take a while...'
      periods.each do |p|
        AccountingPeriod.create!(
          start_at: p[:start_at],
          end_at: p[:end_at],
          closed_at: p[:closed_at],
          closed_by: p[:closed_by]
        )
      end
      # 2. reset protection for AccountingPeriods
      execute("CREATE RULE accounting_periods_del_protect AS ON DELETE TO #{AccountingPeriod.arel_table.name} DO INSTEAD NOTHING;")
    end

    private

    def get_periods(range_start: nil, range_end: nil)
      if range_start && range_end
        AccountingPeriod.where('created_at > ? AND created_at < ?', range_start, range_end)
      elsif range_start
        AccountingPeriod.where('created_at > ?', range_start)
      elsif range_end
        AccountingPeriod.where('created_at < ?', range_end)
      else
        AccountingPeriod.all
      end
    end

    def execute(query)
      ActiveRecord::Base.connection.execute(query)
    end
  end
end
