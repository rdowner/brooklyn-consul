Consul catalog items for Apache Brooklyn
========================================

This package provides Apache Brooklyn catalog items that provide support for deploying Consul agents and server clusters. There are two main components:

* `consul-server-cluster`, a DynamicCluster-based entity that bootstraps a Consul server of any desired size.
* `consul-agent-mixin`, an entity which is intended to be added as a child of a service provider or consumer entity, which integrates Consul agent support onto the same VM.

Usage
-----

First, install the catalog items into your Apache Brooklyn server:

```bash
br catalog add brooklyn-consul/catalog
```

A complete example can be found in [sample-blueprint.yaml](sample-blueprint.yaml). This can be deployed with the command:

```bash
br deploy sample-blueprint-yaml
```


### Consul server cluster

The server cluster is very simple to use. A minimal blueprint would be:

```yaml
- type: consul-server-cluster
  brooklyn.config:
    initialSize: 3
```

The only notable sensor provided by this entity in `consul.joinToken`, which is used by the Consul agent mixin.


### Consul agent mixin

The consul agent mixin is designed to be applied in the `brooklyn.children` section of an entity which either provides or consumes services. The Consul agent will be installed on `localhost` and both the HTTP API and the DNS API will be available. Furthermore, the local DNS resolver will be configured to use the Consul DNS API, so service consumers can simply refer to services by a DNS name and Consul will provide the appropriate IP address.

To integrate the Consul agent mixin, add the following to your service providing/consuming entity:

```yaml
  brooklyn.children:
    - type: consul-agent-mixin
      id: consul-agent-mixin
      brooklyn.config:
        # We link the `consul.joinToken` config key to the consul.joinToken` sensor on the Consul server cluster
        consul.joinToken: $brooklyn:entity("consul-server-cluster").attributeWhenReady("consul.joinToken")
```

`consul.joinToken` is a sensor on the `consul-server-cluster` entity, and a config key on the `consul-agent-mixin`. Linking the two together is how the Consul agent is able to locate and join the Consul server cluster.

We also advise the following configuration (*on the service providing/consuming entity*, not the Consul child entity):

```yaml
    # This option makes the consul agent child entity start in parallel with this one.
    children.startable.mode: foreground
    # We pause before the launch phase to ensure that the consul agent child entity has started fully
    launch.latch: $brooklyn:component("descendant", "consul-agent-mixin").attributeWhenReady("service.isUp")
```

#### Service providers

A service provider can register their service by `PUT`ting a service description to the Consul API running on localhost. Here is an example of using this with a post-launch command:

```yaml
    post.launch.command: |
      echo '{"name": "mysql", "tags": ["todo"], "port": 3306}' > "${RUN_DIR:-/tmp}/register-service.json"
      curl -v --request PUT --data "@${RUN_DIR:-/tmp}/register-service.json" http://localhost:8500/v1/agent/service/register --header "Content-type: application/json"
```

#### Service consumers

If an app wants to locate a service that is in Consul, if all it needs is the IP address, then it can simply refer to a DNS name. For example, to refer to a server which is registered as `mysql` in Consul:

```yaml
    shell.env:
      DB_HOST: 'mysql.service.consul'
```

For more detailed queries, applications can either issue a DNS `SRV` query, or send HTTP requests to the Consul HTTP API on localhost port 8500.


Known limitations
-----------------

It is currently biased towards CentOS 7 systems running NetworkManager. If you are not using CentOS and/or NetworkManager, you will likely see problems.
