# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.action_controller.default_url_options = {
    host: Rails.application.secrets.default_host,
    protocol: Rails.application.secrets.default_protocol
  }

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true


  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = Rails.application.secrets.log_level.blank? ? :debug : Rails.application.secrets.log_level

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # config.serve_static_assets = true

  config.action_mailer.default_url_options = {
    host: Rails.application.secrets.default_host,
    protocol: Rails.application.secrets.default_protocol
  }
  # config.action_mailer.perform_deliveries = true
  # config.action_mailer.raise_delivery_errors = false
  # config.action_mailer.default :charset => "utf-8"

  config.action_mailer.smtp_settings = {
    address: Rails.application.secrets.smtp_address,
    port: Rails.application.secrets.smtp_port,
    user_name: Rails.application.secrets.smtp_user_name,
    password: Rails.application.secrets.smtp_password,
    authentication: Rails.application.secrets.smtp_authentication,
    enable_starttls_auto: Rails.application.secrets.smtp_enable_starttls_auto,
    openssl_verify_mode: Rails.application.secrets.smtp_openssl_verify_mode,
    tls: Rails.application.secrets.smtp_tls
  }

  # use :smtp for switch prod
  config.action_mailer.delivery_method = Rails.application.secrets.delivery_method.to_sym

end

