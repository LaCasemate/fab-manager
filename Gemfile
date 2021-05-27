# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4'
# Used by rails 5.2 to reduce the app boot time by over 50%
gem 'bootsnap'
# Use Puma as web server
gem 'puma', '4.3.8'
gem 'webpacker', '~> 5.x'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jbuilder_cache_multi'
gem 'json', '>= 2.3.0'

gem 'forgery'
gem 'responders', '~> 2.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # comment over to use visual debugger (eg. RubyMine), uncomment to use manual debugging
  # gem 'byebug'
  gem 'dotenv-rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'active_record_query_trace'
  gem 'awesome_print'
  gem 'coveralls_reborn', '~> 0.18.0', require: false
  gem 'foreman'
  gem 'web-console', '>= 3.3.0'
  # Preview mail in the browser
  gem 'listen', '~> 3.0.5'
  gem 'rb-readline'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'railroady'
  gem 'rubocop', '~> 0.61.1', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'database_cleaner'
  gem 'faker'
  gem 'minitest-reporters'
  gem 'pdf-reader'
  gem 'vcr', '3.0.1'
  gem 'webmock'
  gem 'rubyXL'
end

group :production, :staging do
  gem 'rails_12factor'
end

gem 'seed_dump'

gem 'pg'
gem 'pg_search'

# authentication
gem 'devise', '>= 4.6.0'

gem 'omniauth', '~> 1.9.0'
gem 'omniauth-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 0.1'

gem 'rolify'

# pagination
gem 'kaminari'

# Image processing ruby wrapper for ImageMagick
gem 'mini_magick'
# upload files
gem 'carrierwave'

# slug url
gem 'friendly_id', '~> 5.1.0'

# state machine
gem 'aasm'

# Background job processing
gem 'sidekiq', '>= 6.0.7'
# Recurring jobs for Sidekiq
gem 'sidekiq-cron'
gem 'sidekiq-unique-jobs', '~> 6.0.22'

gem 'stripe', '5.29.0'

gem 'recurrence'

# PDF
gem 'prawn'
gem 'prawn-table'

gem 'elasticsearch-model', '~> 5'
gem 'elasticsearch-persistence', '~> 5'
gem 'elasticsearch-rails', '~> 5'
gem 'faraday', '~> 0.17'

gem 'notify_with'

gem 'pundit'

gem 'oj'

gem 'actionpack-page_caching', '1.2.2'
gem 'rails-observers'

gem 'chroma'

gem 'message_format'

gem 'openlab_ruby'

gem 'api-pagination'
gem 'apipie-rails'

# XLS files generation
gem 'caxlsx'
gem 'caxlsx_rails'
gem 'rubyzip', '>= 1.3.0'

# get free disk space
gem 'sys-filesystem'

gem 'sha3'

gem 'repost'

gem 'icalendar'

gem 'tzinfo-data'

# compilation of dynamic stylesheets (home page & theme)
gem 'sassc'
