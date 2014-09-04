wire
====

Wiring up your containers.

So you are all over Docker and want to implement it throughout your stages, from development to production. But your organization challenges you with security concerns, migrating your environments from physical/virtual to Docker seems like a tedious task and those shell scripts that you started to write are reengineered on a weekly basis because more and more requirements are coming in. Suddenly the hoped for simplicity of the Docker approach is gone and you are close to reverting back to the old way of running things, keeping Docker in the development corner at max.

What is de-wiring?
Make your development envs look like production. Build your environments with a model approach and have Dev|Prod-Parity in reach. Instantiate them, from a single Developer VM to multiple hosts in a production enviroment. Specify and document your system, making it testable and audit-proof. Integration with tools from the Test Driven Infrastructure world offer the ability to automatically test what you've specified, including a proper documentation for IT- and Security-Audits.

Why would I want to use it?

Specific uses cases for wire could be:
- Datacenter migration
- Audit and documentation
- Security

build-vm
========

```bash
$ cd build
$ vagrant up
$ vagrant ssh
...
$ cd build
$ rake -T
$ vim
```

test-vm
=======

```bash
$ cd test
$ cd ubuntu
$ vagrant up
```
