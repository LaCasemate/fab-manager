# frozen_string_literal: true

# Correctives for bugs or upgrades migrations tasks
namespace :fablab do
  namespace :fix do
    desc '[release 2.3.0] update reservations referencing reservables not present in database'
    task reservations_not_existing_reservable: :environment do
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.connection.execute(
        'UPDATE reservations SET reservable_type = NULL, reservable_id = NULL'\
        ' WHERE NOT EXISTS (SELECT 1 FROM events WHERE events.id = reservations.reservable_id)'\
        ' AND reservations.reservable_type = \'Event\''
      )
    end

    desc '[release 2.4.0] put every non-categorized events into a new category called "No Category", to ease re-categorization'
    task assign_category_to_uncategorized_events: :environment do
      c = Category.find_or_create_by!(name: 'No category')
      Event.where(category: nil).each do |e|
        e.category = c
        e.save!
      end
    end

    desc '[release 2.4.11] fix is_rolling for edited plans'
    task rolling_plans: :environment do
      Plan.where(is_rolling: nil).each do |p|
        if p.is_rolling.nil? && p.is_rolling != false
          p.is_rolling = true
          p.save!
        end
      end
    end

    desc '[release 2.5.0] create missing plans in statistics'
    task new_plans_statistics: :environment do
      StatisticSubType.where(key: nil).each do |sst|
        p = Plan.find_by(name: sst.label)
        if p
          sst.key = p.slug
          sst.save!
        end
      end
    end

    desc '[release 2.5.5] create missing space prices'
    task new_group_space_prices: :environment do
      Space.all.each do |space|
        Group.all.each do |group|
          begin
            Price.find(priceable: space, group: group)
          rescue ActiveRecord::RecordNotFound
            Price.create(priceable: space, group: group, amount: 0)
          end
        end
      end
    end

    desc '[release 2.5.11] put all admins in a special group'
    task migrate_admins_group: :environment do
      admins = Group.find_by(slug: 'admins')
      User.all.each do |user|
        if user.admin?
          user.group = admins
          user.save!
        end
      end
    end

    desc '[release 2.5.14] fix times of recursive events that crosses DST periods'
    task recursive_events_over_DST: :environment do
      include ApplicationHelper
      failed_ids = []
      groups = Event.group(:recurrence_id).count
      groups.keys.each do |recurrent_event_id|
        next unless recurrent_event_id

        begin
          initial_event = Event.find(recurrent_event_id)
          Event.where(recurrence_id: recurrent_event_id).where.not(id: recurrent_event_id).each do |event|
            availability = event.availability
            next if initial_event.availability.start_at.hour == availability.start_at.hour

            availability.start_at = dst_correction(initial_event.availability.start_at, availability.start_at)
            availability.end_at = dst_correction(initial_event.availability.end_at, availability.end_at)
            availability.save!
          end
        rescue ActiveRecord::RecordNotFound
          failed_ids.push recurrent_event_id
        end
      end

      if failed_ids.size.positive?
        puts "WARNING: The events with IDs #{failed_ids} were not found.\n These were initial events of a recurrence.\n\n" \
             "You may have to correct the following events manually (IDs): #{Event.where(recurrence_id: failed_ids).map(&:id)}"
      end
    end

    desc '[release 2.6.6] reset slug in events categories'
    task categories_slugs: :environment do
      Category.all.each do |cat|
        `curl -XPOST http://#{ENV['ELASTICSEARCH_HOST']}:9200/stats/event/_update_by_query?conflicts=proceed\\&refresh\\&wait_for_completion -d '
        {
          "script": {
            "source": "ctx._source.subType = params.slug",
            "lang": "painless",
            "params": {
              "slug": "#{cat.slug}"
            }
          },
          "query": {
            "term": {
              "subType": "#{cat.name}"
            }
          }
        }';`
      end
    end

    desc '[release 2.4.10] set slugs to plans'
    task set_plans_slugs: :environment do
      # this will maintain compatibility with existing statistics
      Plan.all.each do |p|
        p.slug = p.stp_plan_id
        p.save
      end
    end

    desc '[release 3.1.2] fix users with invalid group_id'
    task users_group_ids: :environment do
      User.where.not(group_id: Group.all.map(&:id)).each do |u|
        u.update_columns(group_id: Group.first.id, updated_at: DateTime.current)

        meta_data = { ex_group_name: 'invalid group' }

        NotificationCenter.call type: :notify_admin_user_group_changed,
                                receiver: User.admins,
                                attached_object: u,
                                meta_data: meta_data

        NotificationCenter.call type: :notify_user_user_group_changed,
                                receiver: u,
                                attached_object: u
      end
    end

    desc '[release 4.3.0] add name to theme stylesheet'
    task name_stylesheet: :environment do
      Stylesheet.order(:created_at).first.update_attributes(
        name: 'theme'
      )
    end

    desc '[release 4.3.3] add statistic_profile_id to refund invoices for WalletTransactions'
    task avoirs_wallet_transaction: :environment do
      Avoir.where(invoiced_type: WalletTransaction.name).each do |a|
        next unless a.statistic_profile_id.nil?

        begin
          a.statistic_profile_id = a.invoiced.wallet.user&.statistic_profile&.id
          a.save!
        rescue ActiveRecord::RecordInvalid => e
          printf "Unable to modify the refund invoice (id %<id>s): %<error>s\nIgnoring that record...\n", id: a.id, error: e
        end
      end
    end

    desc '[release 4.4.2] add missing role to StatisticProfile'
    task role_in_statistic_profile: :environment do
      puts "Fixing #{StatisticProfile.where(role_id: nil).count} bugged profiles...\n"
      StatisticProfile.where(role_id: nil).each do |sp|
        role_id = sp&.user&.roles&.first&.id
        sp.role_id = role_id
        sp.save!
      end
    end

    desc '[release 4.4.3] fix duration of recurring availabilities'
    task availabilities_duration: :environment do
      Availability.select(:occurrence_id).where(is_recurrent: true).group(:occurrence_id).each do |a|
        occurrences = Availability.where(occurrence_id: a.occurrence_id)
        next unless occurrences.map(&:slot_duration).uniq.size > 1

        duration = occurrences.map(&:slot_duration).uniq.detect { |e| !e.nil? }
        occurrences.each do |o|
          o.update_attributes(slot_duration: duration)
        end
      end
    end

    desc '[release 4.7.9] fix invoicing profiles without names'
    task invoices_without_names: :environment do
      InvoicingProfile.where('(first_name IS NULL OR last_name IS NULL) AND user_id IS NOT NULL').each do |ip|
        ip.update_attribute('first_name', ip.user.profile.first_name)
        ip.update_attribute('last_name', ip.user.profile.last_name)
      end
    end
  end
end
