# frozen_string_literal: true

require 'integrity/archive_helper'

# migrate the invoices from being attached to a user to invoicing_profiles which are GDPR compliant
class MigrateInvoiceToInvoicingProfile < ActiveRecord::Migration[4.2]
  def up
    # first, check the footprints
    Integrity::ArchiveHelper.check_footprints

    # if everything is ok, proceed with migration
    # remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods
    # migrate invoices
    puts 'Migrating invoices. This may take a while...'
    Invoice.order(:id).all.each do |i|
      user = User.find(i.user_id)
      operator = User.find_by(id: i.operator_id)
      i.update_column('invoicing_profile_id', user.invoicing_profile.id)
      i.update_column('statistic_profile_id', user.statistic_profile.id)
      i.update_column('operator_profile_id', operator&.invoicing_profile&.id)
      i.update_column('user_id', nil)
      i.update_column('operator_id', nil)
    end
    # chain all records
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)
    # write memory dump into database
    Integrity::ArchiveHelper.restore_periods(periods)
  end

  def down
    # here we don't check footprints to save processing time and because this is pointless when reverting the migrations

    # remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods
    # reset invoices
    Invoice.order(:created_at).all.each do |i|
      i.update_column('user_id', i.invoicing_profile.user_id)
      i.update_column('operator_id', i.operator_profile.user_id)
      i.update_column('invoicing_profile_id', nil)
      i.update_column('statistic_profile_id', nil)
      i.update_column('operator_profile_id', nil)
    end
    # chain all records
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)
    # write memory dump into database
    Integrity::ArchiveHelper.restore_periods(periods)
  end
end
