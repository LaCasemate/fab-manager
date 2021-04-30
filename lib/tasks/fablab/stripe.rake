# frozen_string_literal: true

# Stripe relative tasks
namespace :fablab do
  namespace :stripe do

    desc 'find any invoices with incoherent total between stripe and DB'
    task :find_incoherent_invoices, [:start_date] => :environment do |_task, args|
      puts 'DEPRECATION WARNING: Will not work for invoices created from version 4.1.0 and above'
      date = Date.parse('2017-05-01')
      if args.start_date
        begin
          date = Date.parse(args.start_date)
        rescue ArgumentError => e
          raise e
        end
      end
      Invoice.where('created_at > ? AND stp_invoice_id IS NOT NULL', date).each do |invoice|
        stp_invoice = Stripe::Invoice.retrieve(invoice.stp_invoice_id, api_key: Setting.get('stripe_secret_key'))
        next if invoice.amount_paid == stp_invoice.total

        puts "Id: #{invoice.id}, reference: #{invoice.reference}, stripe id: #{stp_invoice.id}, " \
             "invoice total: #{invoice.amount_paid / 100.0}, stripe invoice total: #{stp_invoice.total / 100.0}, " \
             "date: #{invoice.created_at}"
      end
    end


    desc 'clean stripe secrets from VCR cassettes'
    task clean_cassettes_secrets: :environment do
      Dir['test/vcr_cassettes/*.yml'].each do |cassette_file|
        cassette = File.read(cassette_file)
        cassette = cassette.gsub(Setting.get('stripe_secret_key'), 'sk_test_testfaketestfaketestfake')
        cassette = cassette.gsub(Setting.get('stripe_public_key'), 'pk_test_faketestfaketestfaketest')
        puts cassette
        File.write(cassette_file, cassette)
      end
    end

    desc 'sync users to the stripe database'
    task sync_members: :environment do
      puts 'We create all non-existing customers on stripe. This may take a while, please wait...'
      SyncMembersOnStripeWorker.new.perform
      puts 'Done'
    end
    desc 'sync coupons to the stripe database'
    task sync_coupons: :environment do
      puts 'We create all non-existing coupons on stripe. This may take a while, please wait...'
      Coupon.all.each do |c|
        Stripe::Coupon.retrieve(c.code, api_key: Setting.get('stripe_secret_key'))
      rescue Stripe::InvalidRequestError
        StripeService.create_stripe_coupon(c.id)
      end
      puts 'Done'
    end

    desc 'set stp_product_id to all plans/machines/trainings/spaces'
    task set_product_id: :environment do
      w = StripeWorker.new
      Plan.all.each do |p|
        w.perform(:create_or_update_stp_product, Plan.name, p.id)
      end
      Machine.all.each do |m|
        w.perform(:create_or_update_stp_product, Machine.name, m.id)
      end
      Training.all.each do |t|
        w.perform(:create_or_update_stp_product, Training.name, t.id)
      end
      Space.all.each do |s|
        w.perform(:create_or_update_stp_product, Space.name, s.id)
      end
    end

    desc 'set stripe as the default payment gateway'
    task set_gateway: :environment do
      if Setting.find_by(name: 'stripe_public_key').try(:value) && Setting.find_by(name: 'stripe_secret_key').try(:value)
        Setting.set('payment_gateway', 'stripe') unless Setting.find_by(name: 'payment_gateway').try(:value)
      end
    end

    def print_on_line(str)
      print "#{str}\r"
      $stdout.flush
    end
  end
end
