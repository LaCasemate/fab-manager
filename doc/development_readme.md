# Install Fab-manager in a development environment with Docker

This document will guide you through all the steps needed to set up a development environment for Fab-manager.

##### Table of contents

1. [General Guidelines](#general-guidelines)<br/>
2. [PostgreSQL](#postgresql)
3. [ElasticSearch](#elasticsearch)<br/>
3.1. [Rebuild statistics](#rebuild-stats)<br/>
3.2. [Backup and Restore](#backup-and-restore-elasticsearch)
3.3. [Debugging](debugging-elasticsearch)

This procedure is not easy to follow so if you don't need to write some code for Fab-manager, please prefer the [production installation method](doc/production_readme.md).


<a name="general-guidelines"></a>
## General Guidelines

1. Install RVM, with the ruby version specified in the [.ruby-version file](../.ruby-version).
   For more details about the process, please read the [official RVM documentation](http://rvm.io/rvm/install)

2. Install NVM, with the node.js version specified in the [.nvmrc file](../.nvmrc).
   For instructions about installing NVM, please refer to [the NVM readme](https://github.com/nvm-sh/nvm#installation-and-update).

3. Install Yarn, the front-end package manager.
   Depending on your system, the installation process may differ, please read the [official Yarn documentation](https://yarnpkg.com/en/docs/install#debian-stable).

4. Install docker.
   Your system may provide a pre-packaged version of docker in its repositories, but this version may be outdated.
   Please refer to the [official docker documentation](https://docs.docker.com/engine/install/) to set up a recent version of docker.

5. Add your current user to the docker group, to allow using docker without `sudo`.
   ```bash
   # add the docker group if it doesn't already exist
   sudo groupadd docker
   # add the current user to the docker group
   sudo usermod -aG docker $(whoami)
   # restart to validate changes
   sudo reboot
   ```

6. Retrieve the project from Git

   ```bash
   git clone https://github.com/sleede/fab-manager.git
   ```

7. Move into the project directory and install the docker-based dependencies.
   > ⚠ If you are using MacOS X, you must *first* edit the files located in docker/development to use port binding instead of ip-based binding.
   > This can be achieved by uncommenting the "port" directives and commenting the "networks" directives in the docker-compose.yml file.
   > The hosts file must be modified too, accordingly.

   > ⚠ `ERROR: Pool overlaps with other one on this address space`
   > In this case, you must modify the /etc/hosts and docker-compose.yml files to change the network from 172.18.y.z to 172.x.y.z, where x is a new unused network.

  ```bash
  cd fab-manager
  cat docker/development/hosts | sudo tee -a /etc/hosts
  mkdir -p .docker/elasticsearch/config
  cp docker/development/docker-compose.yml .docker
  cp setup/elasticsearch.yml .docker/elasticsearch/config
  cp setup/log4j2.properties .docker/elasticsearch/config
  cd .docker
  docker-compose up -d
  cd -
  ```

8. Install the other dependencies.
   - For Ubuntu/Debian:

   ```bash
   # on Ubuntu 18.04 server, you may have to enable the "universe" repository
   sudo add-apt-repository universe
   # then, install the dependencies
   sudo apt-get install libpq-dev imagemagick
   ```
   - For MacOS X:

   ```bash
   brew install imagemagick
   ```
   
   - For other systems, please refer to your system specific documentation to install the appropriate packages: ImageMagick and the PostgreSQL development library

9. Init the RVM and NVM instances and check they were correctly configured

   ```bash
   rvm current | grep -q `cat .ruby-version`@fab-manager && echo "ok"
   # Must print ok
   nvm use
   node --version | grep -q `cat .nvmrc` && echo "ok"
   # Must print ok
   ```
   
   If one of these commands does not print "ok", then try to input `rvm use` or `nvm use`

10. Install bundler in the current RVM gemset

   ```bash
   gem install bundler
   ```

11. Install the required ruby gems and javascript plugins

   ```bash
   bundle install
   yarn install
   ```

12. Create the default configuration files **and configure them!** (see the [environment configuration documentation](environment.md))

   ```bash
   cp config/database.yml.default config/database.yml
   cp env.example .env
   vi .env
   # or use your favorite text editor instead of vi (nano, ne...)
   ```

13. Build the databases.
   > **⚠ Warning**: **DO NOT** run `rails db:setup` instead of these commands, as this will not run some required raw SQL instructions.

   > **🛈 Please note**: Your password length must be between 8 and 128 characters, otherwise db:seed will be rejected. This is configured in [config/initializers/devise.rb](config/initializers/devise.rb)

   ```bash
   # for dev
   rails db:create
   rails db:migrate
   ADMIN_EMAIL='youradminemail' ADMIN_PASSWORD='youradminpassword' rails db:seed
   rails fablab:es:build_stats
   # for tests
   RAILS_ENV=test rails db:create
   RAILS_ENV=test rails db:migrate
   ```

14. Create the pids folder used by Sidekiq. If you want to use a different location, you can configure it in [config/sidekiq.yml](config/sidekiq.yml)

   ```bash
   mkdir -p tmp/pids
   ```

15. Start the development web server

   ```bash
   foreman s -p 5000
   ```

16. You should now be able to access your local development Fab-manager instance by accessing `http://localhost:5000` in your web browser.

17. You can log in as the default administrator using the credentials defined previously.

18. Email notifications will be caught by MailCatcher.
    To see the emails sent by the platform, open your web browser at `http://fabmanager-mailcatcher:1080` to access the MailCatcher interface.

<a name="tests"></a>
## Tests

Run the test suite with `./scripts/run-tests.sh`.

Pleas note: If you haven't set the Stripe's API keys in your `.env` file, the script will ask for them.
You must provide valid Stripe API **test keys** for the test suite to run.

<a name="postgresql"></a>
## PostgreSQL

Some information about PostgreSQL usage in fab-manager is available in the [PostgreSQL Readme](postgresql_readme.md).

<a name="elasticsearch"></a>
## ElasticSearch

ElasticSearch is a powerful search engine based on Apache Lucene combined with a NoSQL database used as a cache to index data and quickly process complex requests on it.

In FabManager, it is used for the administrator's statistics module.

The organisation if the data in the ElasticSearch database is documented in [elasticsearch.md](elasticsearch.md) 

<a name="rebuild-stats"></a>
### Rebuild statistics

Every night, the statistics for the day that just ended are built automatically at 01:00 (AM) and stored in ElasticSearch.
See [schedule.yml](config/schedule.yml) to modify this behavior.
If the scheduled task wasn't executed for any reason (e.g. you are in a dev environment, and your computer was turned off at 1 AM), you can force the statistics data generation in ElasticSearch, running the following command.

```bash
# Here for the 50 last days
rails fablab:es:generate_stats[50]
```

<a name="backup-and-restore-elasticsearch"></a>
### Backup and Restore

To back up and restore the ElasticSearch database, use the [elasticsearch-dump](https://github.com/taskrabbit/elasticsearch-dump) tool.

Dump the database with: `elasticdump --input=http://localhost:9200/stats --output=fablab_stats.json`.
Restore it with: `elasticdump --input=fablab_stats.json --output=http://localhost:9200/stats`.


<a name="debugging-elasticsearch"></a>
### Debugging

In development, visit http://fabmanager-kibana:5601 to use Kibana, the web UI for ElasticSearch
