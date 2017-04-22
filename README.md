# [![CircleCI](https://circleci.com/gh/tootsuite/mastodon-ansible.svg?style=svg)](https://circleci.com/gh/tootsuite/mastodon-ansible) Ansible playbook for installing Mastodon

This playbook contains several roles for provisioning a ready-to-go Mastodon instance.

## Prerequisites for running the playbook

- Python 2.x (>= 2.7.12)
- Virtualenv (>= 15.0.3)
- pip/python-pip (>= 8.x)

for testing purposes:

- Vagrant >= 1.9.3

## Setup

```sh
$ virtualenv env
$ source env/bin/activate
$ pip install -r requirements.txt
```
## Running the playbook

```sh
$ ansible-playbook playbook.yml -i <your-host-here>, -u <remote-user> --extra-vars="<extra-variables>"
```

The playbook is using `become` for some of its tasks, hence the user you connect to the instance with will have to have access to sudo. It should ask you for the password in due time.

_Note: This assumes you're within the virtualenv already._

## Roles

By default, the playbook runs all of the roles defined here in sequence. You can skip any of them by specifying `--skip-tags=<role-name>`.

**Example**

Skipping the `postgres` role:

```sh
$ ansible-playbook playbook.yml --skip-tags=postgres -i <your-host>, -u <your-user>
```

### web

This role contains the following tasks:

- `repositories.yml`: **Adds required package repositories** to pull in the latest software (e.g. yarn, nodejs)
- `packages.yml`: **Installs all the required packages** for Mastodon to run (see `vars/<distro>_vars.yml` for a list)
- `ruby.yml`: **Installs rbenv/ruby** globally so you can run Mastodon (it's a Ruby on Rails app)
- `user.yml`: **Adds a user to run Mastodon with** since you shouldn't be running Mastodon under a priviledged account.

### postgres

This role installs PostgresSQL, adds a database (named `mastodon_development` by default) and a user (named `mastodon` by default). For connecting to the database it can either use a local socket by setting the variable `mastodon_db_login_unix_socket` to the directory the Postgres socket lives in (`/var/run/postgresql` by default under Ubuntu 16.04) or a remote PostgreSQL instance you have installed somewhere else. You will than have to set the `mastodon_db_login_host` (IP address or hostname of database), `mastodon_db_port` (the port the database is accessible on; default `5432`), `mastodon_db_login_user` (the administrative user to connect to the database with) and `mastodon_db_login_password`.

**Examples**

- Install PostgresSQL, create the database and user:

```sh
$ ansible-playbook playbook -i <your-host-here>, -u <remote-user> --extra-vars="mastodon_db_password=your-password mastodon_db_login_unix_socket='/var/run/postgresql'"
```
- PostgreSQL installed on host `mastodob-db`, create the database and the user:

```sh
$ ansible-playbook playbook -i <your-host-here>, -u <remote-user> --extra-vars="mastodon_db_password=your-password mastodon_db_login_host=mastodon-db mastodon_db_port=5432 mastodon_db_login_user=your-admin-db-user mastodon_db_login_password=your-password"
```

### redis

This role installs the [Redis](https://redis.io) key-value store, used by Mastodon, and its client libraries.

## Testing

Testing is done using [ServerSpec](https://www.serverspec.org). The tests are located in `spec/`. The tests are incorporating a [rubocop](http://rubocop.readthedocs.io/en/latest/) run.

### CircleCI

This repository is regularly running tests using CircleCI. Its configuration can be found in `.circleci/config.yml`.

### Local testing

```sh
$ vagrant up
```

This should provision a new instance within VirtualBox and run all the tests necessary to verify the Ansible playbook is valid.

# TODO

- Add a firewall/sysctl role for hardening
- Add CentOS/RedHat/Amazon Linux support
- Add LB role
- Add role for actually cloning/initializing Mastodon, including systemd service configurations
