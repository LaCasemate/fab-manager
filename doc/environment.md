# Environment Configuration

##### Table of Contents
1. [Introduction](#introduction)
2. [General settings](#general-settings)
3. [Internationalization settings](#internationalization-settings)
4. [Open projects settings](#open-projects-settings)
5. [Other settings](#other-settings)


<a name="introduction"></a>
## Introduction

The following environment variables configure the addresses of the databases, some credentials, some application behaviours and the localization preferences.
If you are in a development environment, your can keep most of the default values, otherwise, in production, values must be configured carefully.

The settings in [.env](../env.example) configure the environment variables when the application run in development mode.
If you run the application in production with docker, the settings are localized in [config/env](../setup/env.example).

<a name="general-settings"></a>
## General settings
<a name="POSTGRES_HOST"></a>

    POSTGRES_HOST

DNS name or IP address of the server hosting the PostgreSQL database of the application (see [PostgreSQL](../README.md#postgresql)).
This value is only used when deploying in production, otherwise this is configured in [config/database.yml](../config/database.yml.default).
When using docker-compose, you should provide the name of the service in your [docker-compose.yml](../docker/docker-compose.yml) file (`postgres` by default).
<a name="POSTGRES_PASSWORD"></a><a name="POSTGRES_USERNAME"></a>

    POSTGRES_USERNAME, POSTGRES_PASSWORD

Username and password for the connection to the PostgreSQL database.
This value is only used when deploying in production, otherwise this is configured in [config/database.yml](../config/database.yml.default).
When using docker-compose, the default configuration (with `postgres` user) does not uses any password as it is confined in the docker container.
<a name="REDIS_HOST"></a>

    REDIS_HOST

DNS name or IP address of the server hosting the redis database.
When using docker-compose, you should provide the name of the service in your [docker-compose.yml](../docker/docker-compose.yml) file (`redis` by default).
<a name="ELASTICSEARCH_HOST"></a>

    ELASTICSEARCH_HOST

DNS name or IP address of the server hosting the elasticSearch database.
When using docker-compose, you should provide the name of the service in your [docker-compose.yml](../docker/docker-compose.yml) file (`elasticsearch` by default).
<a name="SECRET_KEY_BASE"></a>

    SECRET_KEY_BASE

Used by the authentication system to generate random tokens, eg. for resetting passwords.
Used by Rails to verify the integrity of signed cookies.
You can generate such a random key by running `rails secret`.
<a name="DELIVERY_METHOD"></a>

    DELIVERY_METHOD

Configure the Rails' Action Mailer delivery method.
See http://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.
<a name="SMTP_ADDRESS"></a><a name="SMTP_PORT"></a><a name="SMTP_USER_NAME"></a><a name="SMTP_PASSWORD"></a><a name="SMTP_AUTHENTICATION"></a><a name="SMTP_ENABLE_STARTTLS_AUTO"></a><a name="SMTP_OPENSSL_VERIFY_MODE"></a><a name="SMTP_TLS"></a>

    SMTP_ADDRESS, SMTP_PORT, SMTP_USER_NAME, SMTP_PASSWORD, SMTP_AUTHENTICATION, SMTP_ENABLE_STARTTLS_AUTO, SMTP_OPENSSL_VERIFY_MODE & SMTP_TLS

When DELIVERY_METHOD is set to **smtp**, configure the SMTP server parameters.
See https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration for more details.
<a name="DEFAULT_HOST"></a><a name="DEFAULT_PROTOCOL"></a>

    DEFAULT_HOST, DEFAULT_PROTOCOL

Your members will receive email notifications containing links to your of Fab-manager.
You must properly configure these variables to match URL of this instance, to prevent broken links.
Typically, `DEFAULT_PROTOCOL` will be `https` (`http` if you are in development, or if you set `ALLOW_INSECURE_HTTP`).
The variable `DEFAULT_HOST` should be your domain name (eg. fabmanager.example.com), and is also used for visits statistics (configuration of Google Analytics).
These two variables are also used for SSO authentication.
<a name="LOG_LEVEL"></a>

    LOG_LEVEL

This parameter configures the logs verbosity.
Available log levels can be found [here](http://guides.rubyonrails.org/debugging_rails_applications.html#log-levels).
<a name="MAX_IMAGE_SIZE"></a>

    MAX_IMAGE_SIZE

Maximum size (in bytes) allowed for image uploaded on the platform.
This parameter concerns events, plans, user's avatars, projects and steps of projects.
If this parameter is not specified the maximum size allowed will be 2MB.
<a name="MAX_CAO_SIZE"></a>

    MAX_CAO_SIZE

Maximum size (in bytes) allowed for CAO files uploaded on the platform, as project attachments.
If this parameter is not specified, the maximum size allowed will be 5MB.
<a name="MAX_IMPORT_SIZE"></a>

    MAX_IMPORT_SIZE

Maximum size (in bytes) allowed for import files uploaded on the platform.
Currently, this is only used to import users from a CSV file.
If this parameter is not specified, the maximum size allowed will be 5MB.
<a name="DISK_SPACE_MB_ALERT"></a>

    DISK_SPACE_MB_ALERT

Threshold in MB of the minimum free disk space available on the current mount point.
The check will run every weeks and if the threshold is exceeded, an alert will be sent to every administrators.
<a name="ADMIN_EMAIL"></a><a name="ADMIN_PASSWORD"></a>

    ADMIN_EMAIL, ADMIN_PASSWORD

Credentials for the first admin user created when seeding the project.
By default, these variables are not present in the env file, because they are only used once, when running the database seed with the command `rails db:seed`.
<a name="ADMINSYS_EMAIL"></a>

    ADMINSYS_EMAIL

Optional email of the administrator account in charge of the system administration.
If specified, he will be hidden from the administrators list, and he will exclusively receive the notifications related to the system administration.
If not specified, every administrator will receive system administration notifications.
Please note that setting this parameter does not automatically create the corresponding account in Fab-manager: you must specify here the email of an existing admin account. 
<a name="FORCE_VERSION_CHECK"></a>

    FORCE_VERSION_CHECK

In test and development environments, the version won't be check automatically, unless this variable is set to "true".
<a name="ALLOW_INSECURE_HTTP"></a>

    ALLOW_INSECURE_HTTP

In production and staging environments, the session cookie won't be sent to the server unless through the HTTPS protocol.
If you're using Fab-manager on a non-public network or for testing purposes, you can disable this behavior by setting this variable to `true`.
Please, ensure you know what you're doing, as this can lead to serious security issues. 
<a name="LOCKED_SETTINGS"></a>

    LOCKED_SETTINGS

A comma separated list of settings that cannot be changed from the UI.
Please refer to https://github.com/sleede/fab-manager/blob/master/app/models/setting.rb for a list of possible values.
Only the system administrator can change them, with the command: `ENV=value rails fablab:setup:env_to_db` 

<a name="internationalization-settings"></a>
## Internationalization setting.
<a name="APP_LOCALE"></a>

    APP_LOCALE

Configure application's main localization and translation settings.

See `config/locales/app.*.yml` for a list of available locales. Default is **en**.
<a name="RAILS_LOCALE"></a>

    RAILS_LOCALE

Configure Ruby on Rails localization settings (currency, dates, number formats ...).

Please, be aware that **the configured locale will imply the CURRENCY symbol used to generate invoices**.

_Eg.: configuring **es-ES** will set the currency symbol to **€** but **es-MX** will set **$** as currency symbol, so setting the `RAILS_LOCALE` to simple **es** (without country indication) will probably not do what you expect._

Available values: `en, en-AU-CA, en-GB, en-IE, en-IN, en-NZ, en-US, en-ZA, fr, fa-CA, fr-CH, fr-CM, fr-FR, es, es-419, es-AR, es-CL, es-CO, es-CR, es-DO, 
  es-EC, es-ES, es-MX, es-MX, es-PA, es-PE, es-US, es-VE, pt, pt-BR, zu`.
Default is **en**.

If your locale is not present in that list or any locale doesn't have your exact expectations, please open a pull request to share your modifications with the community and obtain a rebuilt docker image.
You can find templates of these files at https://github.com/svenfuchs/rails-i18n/tree/rails-5-x/rails/locale.
<a name="MOMENT_LOCALE"></a>

    MOMENT_LOCALE

Configure the moment.js library for l10n.

See [github.com/moment/momentlocale/*.js](https://github.com/moment/moment/tree/2.22.2/locale) for a list of available locales.
Default is **en** (even if it's not listed).
<a name="SUMMERNOTE_LOCALE"></a>

    SUMMERNOTE_LOCALE

Configure the javascript summernote editor for l10n.

See [github.com/summernote/summernote/lang/summernote-*.js](https://github.com/summernote/summernote/tree/v0.8.18/lang) for a list of available locales.
Default is **en-US** (even if it's not listed).
<a name="ANGULAR_LOCALE"></a>

    ANGULAR_LOCALE

Configure the locale for angular-i18n.

Please, be aware that **the configured locale will imply the CURRENCY displayed to front-end users.**

_Eg.: configuring **fr-fr** will set the currency symbol to **€** but **fr-ca** will set **$** as currency symbol, so setting the `ANGULAR_LOCALE` to simple **fr** (without country indication) will probably not do what you expect._

See [code.angularjs.org/i18n/angular-locale_*.js](https://code.angularjs.org/1.8.2/i18n/) for a list of available locales. Default is **en**.
<a name="FULLCALENDAR_LOCALE"></a>

    FULLCALENDAR_LOCALE

Configure the fullCalendar JS agenda library.

See [github.com/fullcalendar/fullcalendar/locale/*.js](https://github.com/fullcalendar/fullcalendar/tree/v3.10.2/locale) for a list of available locales. Default is **en-us**.
<a name="INTL_LOCALE"></a>

    INTL_LOCALE

Configure the locale for the javascript Intl Object.
This locale must be a Unicode BCP 47 locale identifier.
See [Intl - Javascript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl#Locale_identification_and_negotiation) for more info about configuring this setting.
<a name="INTL_CURRENCY"></a>

    INTL_CURRENCY

Configure the currency for the javascript Intl Object.
Possible values are the ISO 4217 currency codes, such as "USD" for the US dollar, "EUR" for the euro.
See [Current currency & funds code list](http://www.currency-iso.org/en/home/tables/table-a1.html) for a list of available values. 
There is no default value; this setting MUST be provided.
<a name="POSTGRESQL_LANGUAGE_ANALYZER"></a>

    POSTGRESQL_LANGUAGE_ANALYZER
    
This variable configures the language analyzer for indexing and searching in projets with PostgreSQL.
Available values: `danish, dutch, english, finnish, french, german, hungarian, italian, norwegian, portuguese, romanian, russian, simple, spanish, swedish, turkish`
<a name="TIME_ZONE"></a>

    TIME_ZONE

In Rails: set Time.zone default to the specified zone and make Active Record auto-convert to this zone. Run `rails time:zones:all` for a list of available time zone names.
Default is **UTC**.
<a name="WEEK_STARTING_DAY"></a>

    WEEK_STARTING_DAY

Configure the first day of the week in your locale zone (generally monday or sunday).
<a name="D3_DATE_FORMAT"></a>

    D3_DATE_FORMAT

Date format for dates displayed in statistics charts.
See [D3 Wiki](https://github.com/d3/d3-time-format/blob/v2.2.2/README.md#locale_format) for available formats.
<a name="UIB_DATE_FORMAT"></a>

    UIB_DATE_FORMAT

Date format for dates displayed and parsed in date pickers.
See [AngularUI documentation](https://angular-ui.github.io/bootstrap/#uibdateparser-s-format-codes) for a list available formats.

**BEWARE**: years format with less than 4 digits will result in problems because the system won't be able to distinct dates with the same less significant digits, eg. 50 could mean 1950 or 2050.
<a name="EXCEL_DATE_FORMAT"></a>

    EXCEL_DATE_FORMAT

Date format for dates shown in exported Excel files (eg. statistics)
See [Microsoft support](https://support.microsoft.com/en-us/kb/264372) for a list a available formats.
<a name="ENABLE_IN_CONTEXT_TRANSLATION"></a>

    ENABLE_IN_CONTEXT_TRANSLATION

If set to `true`, and the application in started into a staging environment, this will enable the Crowdin In-context translation layer for the front-end application.
See [Crowdin documentation](https://support.crowdin.com/in-context-localization/) for more details about this.
Accordingly, `RAILS_LOCALE` and `APP_LOCALE` must be configured to `zu`.
<a name="open-projects-settings"></a>
## OpenLab settings
<a name="OPENLAB_BASE_URI"></a>

    OPENLAB_BASE_URI

Set this variable to `https://openprojects.fab-manager.com` if you want to use the common projects repository or set it to your own OpenLab server.

<a name="other-settings"></a>
## Other settings

In the previous versions of Fab-manager, much more settings were configurable from environment variables.
Starting with Fab-manager v4.5.0, these settings can be configured from the graphical interface, when logged as an administrator.

Nevertheless, it is possible to keep the configuration in the `env` file, using a combination of [`LOCKED_SETTINGS`](environment.md#LOCKED_SETTINGS), `rails fablab:setup:env_to_db` and the [mapping table of `env_to_db`](../lib/tasks/fablab/setup.rake#L105).
