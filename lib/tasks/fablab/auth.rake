# frozen_string_literal: true

# SSO and authentication relative tasks
namespace :fablab do
  namespace :auth do

    desc 'switch the active authentication provider'
    task :switch_provider, [:provider] => :environment do |_task, args|
      raise 'FATAL ERROR: You must pass a provider name to activate' unless args.provider

      if AuthProvider.find_by(name: args.provider).nil?
        providers = AuthProvider.all.inject('') { |str, item| str + item[:name] + ', ' }
        raise "FATAL ERROR: the provider '#{args.provider}' does not exists. Available providers are: #{providers[0..-3]}"
      end

      raise "FATAL ERROR: the provider '#{args.provider}' is already enabled" if AuthProvider.active.name == args.provider

      # disable previous provider
      prev_prev = AuthProvider.previous
      prev_prev&.update_attribute(:status, 'pending')

      AuthProvider.active.update_attribute(:status, 'previous')

      # enable given provider
      AuthProvider.find_by(name: args.provider).update_attribute(:status, 'active')

      # migrate the current users.
      if AuthProvider.active.providable_type != DatabaseProvider.name
        # Concerns any providers except local database
        User.all.each(&:generate_auth_migration_token)
      else
        User.all.each do |user|
          # Concerns local database provider
          user.update_attribute(:auth_token, nil)
        end
      end

      # ask the user to restart the application
      next if Rails.env.test?

      puts "\nActivation successful"

      puts "\n/!\\ WARNING: Please consider the following, otherwise the authentication will be bogus:"
      puts "\t1) CLEAN the cache with `rails tmp:clear`"
      puts "\t2) REBUILD the assets with `rails assets:precompile`"
      puts "\t3) RESTART the application"
      puts "\t4) NOTIFY the current users with `rails fablab:auth:notify_changed`\n\n"

    end

    desc 'notify users that the auth provider has changed'
    task notify_changed: :environment do

      I18n.locale = I18n.default_locale

      # notify every users if the provider is not local database provider
      if AuthProvider.active.providable_type != DatabaseProvider.name
        User.all.each do |user|
          NotificationCenter.call type: 'notify_user_auth_migration',
                                  receiver: user,
                                  attached_object: user
        end
      end

      puts "\nUsers successfully notified\n\n"
    end
  end
end
