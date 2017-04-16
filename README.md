# Ansible playbook for installing Mastodon

This playbook contains several roles for provisioning a ready-to-go Mastodon instance:

- `basic`: The basics for running Mastodon, mostly Ruby related
- `postgres`: A role for installing a [PostgreSQL](https://www.postgresql.org/) database, the databse used by Mastodon
- `redis`: A role for installing the key-value store [Redis](https://redis.io), used by Mastodon for caching purposes

## Prerequisites

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
$ ansible-playbook playbook.yml -i <your-host-here> -u <remote-user>
```

The playbook is using `become` for some of its tasks, hence the user you connect to the instance with will have to have access to sudo. It should ask you for the password in due time.

_Note: This assumes you're within the virtualenv already._

## Testing

```sh
$ vagrant up
```

This should provision a new instance within VirtualBox and run all the tests necessary to verify the Ansible playbook is valid.

_Note: This assumes you're within the virtualenv already._

# TODO

- Add a firewall/sysctl role for hardening
- Add CentOS/RedHat/Amazon Linux support
