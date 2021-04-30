# frozen_string_literal: true

require 'integrity/archive_helper'

# regenerate the accounting periods affected by the current bug (period totals are wrong due to wrong VAT computation)
class FixAccountingPeriods < ActiveRecord::Migration[5.2]
  def change
    # first, check the footprints
    Integrity::ArchiveHelper.check_footprints

    # if everything is ok, proceed with migration
    # remove periods (backup their parameters in memory)
    periods = Integrity::ArchiveHelper.backup_and_remove_periods(range_start: '2019-08-01', range_end: '2020-05-12')
    # recreate periods from memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end
end
