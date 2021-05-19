# cnp-module-elk

This repository contains the module that enables you to create an ElasticSearch cluster IaaS.

## Variables

### Configuration

The following parameters are required by the module

- `product` this is the name of the product or project i.e. probate, divorce etc.
- `location` this is the azure region for this service
- `env` this is used to differentiate the environments e.g dev, prod, test etc
- `common_tags` tags that need to be applied to every resource group, passed through by the jenkins-library
- `alerts_email` used to send basic alerts configured in [alerts.tf](alerts.tf)
- `vmHostNamePrefix` used to prefix hosts, Can be up to 5 characters in length.
- `vNetLoadBalancerIp`private ip for attatching to load balancer

### Output

The following values are provided by the module for use in other modules

- `loadbalancer` the host name which can be used to connect to Elastic
- `loadbalancerManual` the host name which can be used to connect to Elastic
- `kibana` the primary access key required to connect
- `jumpboxssh` the port on which Redis is running
- `elastic_resource_group_name` the name of the created azure elastic resource group
- `logstash_resource_group_name` the name of the created azure logstash resource group
