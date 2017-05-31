# SPAM (Smart Proxy Alb Manager)
CLI Tool to manage AWS ALB Target Groups and Rules for a Single Listner to setup Foreman Smart Proxies in bulk

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [SPAM (Smart Proxy Alb Manager)](#spam-smart-proxy-alb-manager)
	- [Prerequisites](#prerequisites)
	- [Info](#info)
		- [Is It For Me?](#is-it-for-me)
		- [What Does it Do?](#what-does-it-do)
	- [Usage](#usage)
		- [Install](#install)
			- [Global Install](#global-install)
			- [Local Install](#local-install)
		- [Config](#config)
			- [SPAM](#spam)
- [Optional Settings](#optional-settings)
			- [AWS](#aws)
		- [Commands](#commands)
			- [Chef](#chef)
				- [Commands](#commands)
				- [Flags/Options](#flagsoptions)
	- [Use Cases](#use-cases)
		- [Complete Setup](#complete-setup)
		- [Existing Docker Swarm](#existing-docker-swarm)
	- [Development](#development)
	- [How to Contribute](#how-to-contribute)
		- [External Contributors](#external-contributors)
		- [Internal Contributors](#internal-contributors)

<!-- /TOC -->

## Prerequisites

-   Ruby 2.3 or later
-   Docker 1.12 or later
-   Bundler

## Info

### Is It For Me?
SPAM is a CLI Tool to support The Foreman Smart Proxies and Plugins for the following type of situations

1.  Using AWS?
2.  Already Have a ALB and Endpoint Created (or using Cloudformation)?
3.  Chef Users
    -   Multi-Chef Orgs that need a smart proxy each?
    -   Mutli-Chef Orgs that match Foreman Organizations and need Smart Proxies for each Chef Org, under each Foreman Org?



### What Does it Do?
SPAM Wraps the Docker API, AWS API, and Foreman API so it can act as the glue or coordinator between these services to create smart proxies in bulk.

1.  Docker Swarm
    -   Create a Swarm (Optional, can just Provide Swarm Manager IP for existing Swarm)
    -   Join a Swarm (Optional, can use docker cli instead)
2.  Creates Docker Service using (Optional, can just provide port for org container) [Dockerized Foreman Chef Smart Proxy](https://github.com/HearstAT/docker_foreman_smart_proxy_chef) for a specified org
3.  Creates Target Group for Chef Org to Route traffic to created Smart Proxy
4.  Creates Rule to forward based on proxy_url + org path (e.g. `https://proxy.domain.com/org`)
5.  Registers Target(s) (aka Instances) for ALB to round robin to
    -   Can be single or mutliple. Recommended to just add each instance you run SPAM on
6.  Create Smart Proxy in Foreman with all data from above
7.  Write out all relevent data to YAML file for org creations (Swarm, ALB, and Foreman) so you can query or delete SPAM managed items
8.  Sync org data files (YAMLs) to S3 (Optional, only syncs if --bucket-name flag is used or in `~/.spam/config./yml`)
    -   Done after every create
    -   Done before every list and delete

## Usage

### Install

#### Global Install

Run the following

```bash
gem install bundler
bundle install
```
#### Local Install

```bash
gem install bundler
bundle install --path vendor/bundle
```
### Config

#### SPAM
Any [flag/option](#flags_options) can be configured via YAML for options that won't change

**NOTE**: Only recommended settings are show below, things like org, port, priority, tagets should be dynamic

`~/.spam/config./yml`
```yaml
---
vpc: VPC
listener_arn: ARN
foreman_user: USER
foreman_password: PASSWORD
proxy_url: https://proxy.domain.com
# Optional Settings
aws_region: REGION
protocol: HTTP
swarm_ip: IP
swarm_as: worker/manager
swarm_join: true/False
chef_url: https://chef.domain.com
```

#### AWS
Default credentials are loaded automatically from the following locations:

-   `ENV['AWS_ACCESS_KEY_ID']` and `ENV['AWS_SECRET_ACCESS_KEY']`
-   `Aws.config[:credentials]`
-   The shared credentials ini file at `~/.aws/credentials`
-   From an instance profile when running on EC2

### Commands

Commands to interact with Docker, AWS ALB, and The Foreman

**NOTE**: Chef is the only support Smart Proxy setup currently, as we expand our integrations and services we will add more to the tool. Pull Request always welcome!

#### Chef

##### Commands

| Command |                                        Description                                         |
| ------- | ------------------------------------------------------------------------------------------ |
| Create  | Creates the Chef Org Proxy on Dockerhost, ALB Rules/Paths, and adds Smart Proxy to Foreman |
| Delete  | Deletes all items generated by Create Command                                              |
| Add     | Command to add targets to specific Org Configuration                                       |
| List    | List current SPAM Configs/Orgs                                                             |

##### Flags/Options

| Arg | Description |
| --- | ----------- |
|     |             |

## Use Cases

### Complete Setup

### Existing Docker Swarm

## Development

## How to Contribute

### External Contributors

-   Fork the repo on [Github](https://github.com/HearstAT/SPAM)
-   Clone the project to your own machine
-   Commit changes to your own branch
-   Push your work back up to your fork
-   Submit a Pull Request so that we can review your changes

**NOTE**: Be sure to merge the latest from "upstream" before making a pull request!

### Internal Contributors

-   Clone the project to your own machine
-   Create a new branch from master
-   Commit changes to your own branch
-   Push your work back up to your branch
-   Submit a Pull Request so the changes can be reviewed

**NOTE**: Be sure to merge the latest from "upstream" before making a pull request!
