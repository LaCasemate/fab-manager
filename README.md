# Fab-manager

Fab-manager is the Fab Lab management solution. It provides a comprehensive, web-based, open-source tool to simplify your administrative tasks, and document your marker's projects.

[![Coverage Status](https://coveralls.io/repos/github/sleede/fab-manager/badge.svg)](https://coveralls.io/github/sleede/fab-manager)
[![Docker pulls](https://img.shields.io/docker/pulls/sleede/fab-manager.svg)](https://hub.docker.com/r/sleede/fab-manager/)
[![Docker Build Status](https://img.shields.io/docker/cloud/build/sleede/fab-manager.svg)](https://hub.docker.com/r/sleede/fab-manager/builds)
[![Crowdin](https://badges.crowdin.net/fab-manager/localized.svg)](https://crowdin.com/project/fab-manager)

##### Table of Contents
1. [Software stack](#software-stack)
2. [Contributing](#contributing)
3. [Setup a production environment](#setup-a-production-environment)
4. [Setup a development environment](#setup-a-development-environment)
5. [Internationalization (i18n)](#i18n)
6. [Open Projects](#open-projects)
7. [Plugins](#plugins)
8. [Single Sign-On](#sso)
9. [Known issues](#known-issues)
10. [Related Documentation](#related-documentation)



<a name="software-stack"></a>
## Software stack

Fab-manager is a Ruby on Rails / AngularJS web application that runs on the following software:

- Ubuntu LTS 14.04+ / Debian 8+
- Ruby 2.6
- Redis 6
- Sidekiq 6
- Elasticsearch 5.6
- PostgreSQL 9.6

<a name="contributing"></a>
## Contributing

Contributions are welcome. Please read [the contribution guidelines](CONTRIBUTING.md) for more information about the contribution process.

<a name="setup-a-production-environment"></a>
## Setup a production environment

To run Fab-manager as a production application, you must follow the procedure described in the [production readme](doc/production_readme.md).
This procedure is using [Docker-compose](https://docs.docker.com/compose/overview/) to manage the application and its dependencies.

<a name="setup-a-development-environment"></a>
## Setup a development environment

In you intend to run Fab-manager on your local machine to contribute to the project development, you can set it up by following the [development readme](doc/development_readme.md). 
This procedure relies on [Docker-compose](https://docs.docker.com/compose/overview/) to set-up the dependencies.

Optionally, you can use a virtual development environment that relies on Vagrant and Virtual Box by following the [virtual machine instructions](doc/virtual-machine.md).

<a name="i18n"></a>
## Internationalization (i18n)

The Fab-manager application can only run in a single language but this language can easily be changed.

Please refer to the [translation readme](doc/translation_readme.md) for instructions about configuring the language or to contribute to the translation.

<a name="open-projects"></a>
## Open Projects

**This configuration is optional.**

You can configure your Fab-manager to synchronize every project with the [Open Projects platform](https://github.com/sleede/openlab-projects).
It's very simple and straightforward and in return, your users will be able to search over projects from all Fab-manager instances from within your platform.
The deal is fair, you share your projects and as reward you benefits from projects of the whole community.

If you want to try it, you can visit [this Fab-manager](https://fablab.lacasemate.fr/#!/projects) and see projects from different Fab-managers.

To start using this awesome feature, there are a few steps:
- send a mail to **contact@fab-manager.com** asking for your Open Projects client's credentials and giving them the name and the URL of your Fab-manager, they will give you an `App ID` and a `secret`
- fill in the value of the keys in Admin > Projects > Settings > Projects sharing
- export your projects to open-projects (if you already have projects created on your Fab-manager, unless you can skip that part) executing this command: `bundle exec rails fablab:openlab:bulk_export`

**IMPORTANT: please run your server in production mode.**

Go to your projects gallery and enjoy seeing your projects available from everywhere ! That's all.

<a name="plugins"></a>
## Plugins

Fab-manager has a system of plugins mainly inspired by [Discourse](https://github.com/discourse/discourse) architecture.

It enables you to write plugins which can:
- have its proper models and database tables
- have its proper assets (js & css)
- override existing behaviours of Fab-manager
- add features by adding views, controllers, ect...

To install a plugin, you just have to copy the plugin folder which contains its code into the folder `plugins` of Fab-manager.

You can see an example on the [repo of navinum gamification plugin](https://github.com/sleede/navinum-gamification)

<a name="sso"></a>
## Single Sign-On

Fab-manager can be connected to a [Single Sign-On](https://en.wikipedia.org/wiki/Single_sign-on) server which will provide its own authentication for the platform's users.
Currently, OAuth 2 is the only supported protocol for SSO authentication.

For an example of how to use configure an SSO in Fab-manager, please read [sso_with_github.md](doc/sso_with_github.md).

<a name="known-issues"></a>
## Known issues

Before reporting an issue, please check if your issue is not listed in the [know issues](doc/known-issues.md) with its solution. 

<a name="related-documentation"></a>
## Related Documentation

- [Ruby 2.6.5](http://ruby-doc.org/core-2.6.5/)
- [Ruby on Rails](http://api.rubyonrails.org)
- [AngularJS](https://docs.angularjs.org/api)
- [Angular-Bootstrap](http://angular-ui.github.io/bootstrap/)
- [ElasticSearch 5.6](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/index.html)
