# [![CircleCI](https://circleci.com/gh/tootsuite/mastodon-ansible.svg?style=svg)](https://circleci.com/gh/tootsuite/mastodon-ansible) Ansible playbook for installing Mastodon

This playbook contains several roles for provisioning a ready-to-go Mastodon instance.

## Prerequisites for running the playbook

- Python 3.x
- Virtualenv (>= 15.0.3)
- pip/python-pip (>= 8.x)

for testing purposes:

- Vagrant >= 1.9.3

## Setup

```sh
$ virtualenv -p /usr/bin/python3 env
$ source env/bin/activate
$ git clone https://github.com/mastodon/mastodon-ansible.git
$ cd mastodon-ansible
$ pip install -r requirements.txt
```
## Running the playbooks

### Bare

This playbook is intended to be run on a "bare" (virtual) server, with the support for provisioning the Mastodon stack as well as a PostgresSQL and Redis database.

Typing secret content directly at the command line (without a prompt) leaves the secret string in your shell history. You should use [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to secure your Mastodon database credentials for the use with Ansible instead.

The `/templates/secrets.yml.tpl` contains an example template that you can use.

To encrypt `secrets.yml`, use this following command:

```sh
$ ansible-vault encrypt secrets.yml
```

Then run the playbook as following:

```sh
$ ansible-playbook playbook.yml --ask-vault-pass -i <your-host-here>, -u <remote-user> --ask-become-pass -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars="@secrets.yml"
```

If you prefer not to use Ansible Vault, you can run the playbook as following:

```sh
$ ansible-playbook playbook.yml -i <your-host-here>, -u <remote-user> --ask-become-pass -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars="mastodon_db_password=your-password redis_pass=your-password mastodon_host=example.com"
```

The playbook is using `become` for some of its tasks, hence the user you connect to the instance with will have to have access to sudo. It should ask you for the password in due time.

_Note: This assumes you're within the virtualenv already._

After the playbook has finished its execution, Mastodon now should be available at the hostname you defined and you're not required run the mastodon setup wizard. As Email servers differ widly from configuration to configuration **you must edit the .env.production file and add your own email server details followed by restart of Mastodon services.**

To edit .env.production, follow these steps:

```bash
ssh yourmachine
su - mastodon
cd ~/live
nano .env.production
systemctl restart mastodon-*.service
```

To see a list of available environment variables for your Mastodon installation, please refer to the [Mastodon Configuring your environment documentation](https://docs.joinmastodon.org/admin/config/).


#### Roles

By default, the playbook runs all of the roles defined here in sequence. You can skip any of them by specifying `--skip-tags=<role-name>`.

##### Example

Skipping the `postgres` role:

```sh
$ ansible-playbook playbook.yml --skip-tags=postgres -i <your-host>, -u <your-user>
```

#### web

This role contains the following tasks:

- `repositories.yml`: **Adds required package repositories** to pull in the latest software (e.g. yarn, nodejs)
- `packages.yml`: **Installs all the required packages** for Mastodon to run (see `vars/<distro>_vars.yml` for a list)
- `ruby.yml`: **Installs rbenv/ruby** globally so you can run Mastodon (it's a Ruby on Rails app)
- `user.yml`: **Adds a user to run Mastodon with** since you shouldn't be running Mastodon under a privileged account.
- `firewall-cmd.yml`: **Starts and enables firewall for RHEL based systems** and permitting SSH, HTTP and HTTPS, as not using a firewall is insecure.
- `ufw.yml`: **Starts and enables firewall for Debian based systems** and permitting SSH, HTTP and HTTPS, as not using a firewall is insecure.
- `mastodon.yml`: **Downloads and installs latest version of Mastodon** and all of its required dependencies. This role generates required secrets and installs env.production file, not requiring to run the Mastodon setup wizard.
- `nginx.yml`: **Installs Mastodon configuration for NGINX** and sets correct SELinux policies for RHEL systems.
- `nodejs.yml`: **Enables NodeJS 16 DNF module for RHEL 8+ systems** to ensure that we have correct NodeJS version installed.
- `redis.yml`: **Secures Redis installation with a password** as you shouldn't run redis with no password protection.
- `selfsigned-ssl.yml`: **Generates self-signed SSL certificates when LetsEncrypt not used** as Mastodon requires SSL to function.

##### Settings

| config setting  | explanation |
|-----------------|-------------|
| mastodon_host                 | The url where your mastodon instance is reachable. E.g. `example.social`
| disable_hsts                  | Per default the system will enable [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security). You can set this to `true` if you want to disable it.
| disable_letsencrypt           | Per default the system will attempt to obtain SSL certificate via LetsEncrypt. You can set this to `true` if you want to disable it.
| use_http                      | Per default the system will use HTTPS and redirect any HTTP traffic to HTTPS. Useful for development or reverse proxy scenarios. You can set this to `true` if you want to enable it.

#### PostgresSQL

This role installs PostgresSQL, adds a database (named `mastodon_development` by default) and a user (named `mastodon` by default). For connecting to the database it can either use a local socket by setting the variable `mastodon_db_login_unix_socket` to the directory the Postgres socket lives in (`/var/run/postgresql` by default under Ubuntu 18.04) or a remote PostgreSQL instance you have installed somewhere else. You will than have to set the `mastodon_db_login_host` (IP address or hostname of database), `mastodon_db_port` (the port the database is accessible on; default `5432`), `mastodon_db_login_user` (the administrative user to connect to the database with) and `mastodon_db_login_password`.

##### Settings

| config setting  | explanation |
|-----------------|-------------|
| mastodon_db                   | The database name
| mastodon_db_user              | Database user for mastodon
| mastodon_db_password          | Database password for mastodon
| mastodon_db_login_unix_socket | Unix socket of the local PostgresSQL instance (not needed when using remote connection)

If you configure your PostgresSQL on another server, you need
to configure these settings additionally:

| config setting  | explanation
|-----------------|-------------|
| mastodon_db_login_host     | Host of the PostgresSQL
| mastodon_db_port           | Port of the PostgresSQL
| mastodon_db_login_user     | Admin user to connect with
| mastodon_db_login_password | Password of admin user


##### Examples

- Install PostgresSQL, create the database and user:

```sh
$ ansible-playbook playbook -i <your-host-here>, -u <remote-user> --extra-vars="mastodon_db_password=your-password mastodon_db_login_unix_socket='/var/run/postgresql'"
```

- PostgreSQL installed on host `mastodob-db`, create the database and the user:

```sh
$ ansible-playbook playbook -i <your-host-here>, -u <remote-user> --extra-vars="mastodon_db_password=your-password mastodon_db_login_host=mastodon-db mastodon_db_port=5432 mastodon_db_login_user=your-admin-db-user mastodon_db_login_password=your-password"
```

#### redis

This role installs the [Redis](https://redis.io) key-value store, used by Mastodon, and its client libraries.

##### Settings

| config setting  | explanation |
|-----------------|-------------|
| redis_pass                    | Password used to secure the redis server.

### Docker

FIXME

## Testing

Testing is done using [ServerSpec](https://serverspec.org). The tests are located in `spec/`. The tests are incorporating a [rubocop](http://rubocop.readthedocs.io/en/latest/) run.

### CircleCI

This repository is regularly running tests using CircleCI. Its configuration can be found in `.circleci/config.yml`.

### Local testing

```sh
$ vagrant up bare|docker
```

This should provision a new instance within VirtualBox and run all the tests necessary to verify the Ansible playbook is valid. By default it runs the bare provisioning.

# TODO

- Add letsencrypt
- Add CentOS/RedHat/Amazon Linux support
- Add LB role
