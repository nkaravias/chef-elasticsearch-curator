# omc_curator Cookbook

Deploys the curator container and configures possible certificate files. If there is an updated docker image file this cookbook will pull it and trigger a redeployment of the existing containers. The same thing will happen if there's a change in the docker container resource (e.g a container environment attribute was changed). 

## Requirements

### Platforms

- Oracle Linux 

### Chef

- Chef 12.0 or later

### Cookbooks

- `docker` - https://supermarket.chef.io/cookbooks/docker

## Attributes

### omc_curator::default

default[:omc_curator][:registry]='10.88.249.32:5000'
default[:omc_curator][:image]='elqcurator'
default[:omc_curator][:tag]='release'
default[:omc_curator][:curator_dbag_info]=[]#[{dbag,item}]
default[:omc_curator][:curator_ssl_dbag_info]=[]#[{dbag,item,key}]
default[:omc_curator][:curator_workdir]='/scratch/curator'
default[:omc_curator][:ssl_path]='/scratch/curator/ssl'

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['omc_curator']['registry']</tt></td>
    <td>String</td>
    <td>registry uri e.g 127.0.0.1:5000</td>
    <td><tt></tt></td>
  </tr>
  <tr>
    <td><tt>['omc_curator']['image']</tt></td>
    <td>String</td>
    <td>docker image name</td>
    <td><tt>elqcurator</tt></td>
  </tr>
  <tr>
    <td><tt>['omc_curator']['tag']</tt></td>
    <td>String</td>
    <td>docker image tag</td>
    <td><tt>release</tt></td>
  </tr>
  <tr>
    <td><tt>['omc_curator']['curator_dbag_info']</tt></td>
    <td>Array</td>
    <td>Array of hashes e.g [ { "databag_name":"curator_config_A" }]</td>
    <td><tt>empty</tt></td>
  </tr>
  <tr>
    <td><tt>['omc_curator']['curator_ssl_dbag_info']</tt></td>
    <td>Hash</td>
    <td>Single object hash e.g { "databag_name":"certificate_item" }</td>
    <td><tt>empty</tt></td>
  </tr>
  <tr>
    <td><tt>['omc_curator']['curator_work_dir']</tt></td>
    <td>String</td>
    <td>Location where docker will exec for each curator container</td>
    <td><tt>/scratch/curator</tt></td>
  </tr>
  <tr>
    <td><tt>['omc_curator']['curator_ssl_path']</tt></td>
    <td>String</td>
    <td>Location where required TLS certificates are placed</td>
    <td><tt>/scratch/curator/ssl</tt></td>
  </tr>
</table>

## Data bags 

### Certificates
By default it is assumed that curator is targetting a secure elasticsearch cluster (xpack::security.enabled). The required certificates are the elasticsearch TLS certificate, it's key and the CA file. Each certificate needs to be transformed to base64 and stored in the encrypted data bag defined by the attribute ['omc_curator']['curator_ssl_dbag_info']. This data bag needs to have the following structure (the keys are hardcoded in the recipe):
```json
{
  "id": "curator_example_certs",
  "elasticsearch.ssl.cert": "base64hash",
  "elasticsearch.ssl.key": "base64hash",
  "ca.ssl.cert": "base64hash
}
```

### Curator instance configuration
The curator container only supports one index pattern. This means that for each additional index the recipe will create a separate docker container. The configuration for each container is stored in the encrypted data bags defined in the array of hashes ['omc_curator']['curator_dbag_info'] e.g [ { "databag_name":"curator_config_A" }]. An example looks like this:
```json
{
  "id": "kitchen-index-A",
  "hostname": "curator-A",
  "env_attrs": {
    "INDEX_PREFIX": "index-A",
    "ES_HOST": "localhost",
    "ES_PORT": 9200,
    "ES_USER": "elastic",
    "ES_PASS": "changeme",
    "ACTION_DELETE_DISABLED": "False",
    "ACTION_DELETE_DRYRUN": "False",
    "DELETE_UNIT": "minutes",
    "DELETE_UNIT_VALUE": 5,
    "DELETE_MINUTE": 22,
    "DELETE_HOUR": "*",
    "ACTION_FMERGE_DISABLED": "False",
    "ACTION_FMERGE_DRYRUN": "False",
    "FMERGE_UNIT": "minutes",
    "FMERGE_UNIT_VALUE": 5,
    "FMERGE_MINUTE": 5,
    "FMERGE_HOUR": "*",
    "FMERGE_DELAY_SEC": 120,
    "FMERGE_SEGMENT_NUM": 1
  }
}
```

### Docker volumes
The containers created by omc_curator create and mount the following docker volumes onto each curator container: 
```
 node[:omc_curator][:ssl_path]:/ssl
 /var/log/['hostname']:/logs # hostname is derived from the curator instance configuration data bag
```

## Usage

### omc_curator::default

TODO: Write usage instructions for each cookbook.

Include `omc_curator` in your node's `run_list`. For each separate elasticsearch index managed by curator you will need a separate container running. A role for each use case is required:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[omc_curator]",
    "role[curator-index-A]",
    ...
    "role[curator-index-N]"
  ]
}
```

## Contributing

TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

## License and Authors

Authors: nikolas.karavias@oracle.com / karavias.nikos@gmail.com

