# frozen_string_literal: true

# Maintenance tasks
namespace :fablab do
  namespace :maintenance do
    desc 'Regenerate the invoices (invoices & avoirs) PDF'
    task :regenerate_invoices, %i[year month] => :environment do |_task, args|
      year = args.year || Time.current.year
      month = args.month || Time.current.month
      start_date = Time.zone.local(year.to_i, month.to_i, 1)
      end_date = start_date.next_month
      puts "-> Start regenerate the invoices PDF between #{I18n.l start_date, format: :long} and " \
         "#{I18n.l end_date - 1.minute, format: :long}"
      invoices = Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: start_date, end_date: end_date)
                        .order(created_at: :asc)
      invoices.each(&:regenerate_invoice_pdf)
      puts '-> Done'
    end

    task :regenerate_schedules, %i[year month] => :environment do |_task, args|
      year = args.year || Time.current.year
      month = args.month || Time.current.month
      start_date = Time.zone.local(year.to_i, month.to_i, 1)
      end_date = start_date.next_month
      puts "-> Start regenerate the payment schedules PDF between #{I18n.l start_date, format: :long} and " \
         "#{I18n.l end_date - 1.minute, format: :long}"
      schedules = PaymentSchedule.where('created_at >= :start_date AND created_at < :end_date', start_date: start_date, end_date: end_date)
                                 .order(created_at: :asc)
      schedules.each(&:regenerate_pdf)
      puts '-> Done'
    end

    desc 'recreate every versions of images'
    task build_images_versions: :environment do
      Project.find_each do |project|
        if project.project_image.present? && project.project_image.attachment.present?
          project.project_image.attachment.recreate_versions!
        end
      end
      ProjectStepImage.find_each do |project_step_image|
        project_step_image.attachment.recreate_versions! if project_step_image.present? && project_step_image.attachment.present?
      end
      Machine.find_each do |machine|
        machine.machine_image.attachment.recreate_versions! if machine.machine_image.present?
      end
      Event.find_each do |event|
        event.event_image.attachment.recreate_versions! if event.event_image.present?
      end
    end

    desc 'generate current code checksum'
    task checksum: :environment do
      require 'integrity/checksum'
      puts Integrity::Checksum.code
    end

    desc 'delete users with accounts marked with is_active=false'
    task delete_inactive_users: :environment do
      count = User.where(is_active: false).count
      if count.positive?
        print "WARNING: You are about to delete #{count} users. Are you sure? (y/n) "
        confirm = STDIN.gets.chomp
        next unless confirm == 'y'

        User.where(is_active: false).map(&:destroy!)
      else
        puts 'No inactive users to delete'
      end
    end

    desc '(re)build customization stylesheet'
    task rebuild_stylesheet: :environment do
      Stylesheet.build_theme!
    end

    desc 'migration notifications from Fab-manager v1'
    task migrate_v1_notifications: :environment do
      Notification.where(notification_type_id: 4).each do |n|
        n.notification_type_id = 11
        n.save!
      end
    end

    desc 'get the version'
    task version: :environment do
      require 'version'
      puts Version.current
    end

    desc 'clean the cron workers'
    task clean_workers: :environment do

      Sidekiq::Cron::Job.destroy_all!
      Sidekiq::Queue.new('system').clear
      Sidekiq::Queue.new('default').clear
      Sidekiq::DeadSet.new.clear
    end

    desc 'save the footprint original data'
    task save_footprint_data: :environment do
      [Invoice, InvoiceItem, HistoryValue, PaymentSchedule, PaymentScheduleItem].each do |klass|
        klass.all.each do |item|
          FootprintDebug.create!(
            footprint: item.footprint,
            data: FootprintService.footprint_data(klass, item),
            klass: klass
          )
        end
      end
    end
  end
end
