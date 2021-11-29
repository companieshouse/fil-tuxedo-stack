# Deploy role

This role implements a sequence of tasks required to deploy Tuxedo FIL services and configuration.

## Table of contents

* [Overview][1]
* [Configuration][2]
    * [Services][3]
    * [Logging][4]

[1]: #overview
[2]: #configuration
[3]: #services
[4]: #logging

## Overview

This role encapsulates the tasks required to deploy Tuxedo services to cloud-based hosts.

## Configuration

The following sections detail the different areas of configuration supported by this role.

### Services

Tuxedo services are configured using the `tuxedo_service_config` variable. A default configuration has been provided for the full set of services expected to operate in the development, staging, and production environments. This variable is defined as a dictionary of dictionaries whose keys represent separate groups of Tuxedo services. Each group corresponds to a Linux user login and provides a level of separation between logically related services (e.g. `cabs`, `ef`, `prod`, `scud`).

Each dictionary must include the following parameters unless marked _optional_:

| Name                    | Default | Description                                                                           |
|-------------------------|---------|---------------------------------------------------------------------------------------|
| `ipc_key`               |         | A unique IPC key value for Tuxedo services.                                           |
| `local_domain_port`     |         | The port number to use for the local Tuxedo domain.                                   |
| `queue_space_ipc_key`   |         | A unique IPC key value for the primary Tuxedo queue space.                            |
| `queue_space_2_ipc_key` |         | _Optional_. A unique IPC key value for services that use a second Tuxedo queue space. |
| `tuxedo_log_size`       |         | The log size to use when creating the Tuxedo queue(s).                                |

A `tuxedo_service_users` variable is required when running this role and can be provided using the `-e|--extra-vars` option to the `ansible-playbook` command. This variable should be defined as a list of group names to be deployed, where each group name corresponds to a key in the `tuxedo_service_config` configuration variable discussed above. For example, to deploy only services belonging to the `cabs` group:

```shell
ansible-playbook -i inventory --extra-vars='{"tuxedo_service_users": ["cabs"]}'
```

### Logging

Log data can be pushed to CloudWatch log groups automatically and is controlled by the `tuxedo_log_files` configuration variable. This variable functions in a manner similar to `tuxedo_service_config` (see [Services][3]), whereby each key represents the configuration for a named group of Tuxedo services, each of which corresponds to a user account on the remote host.

`tuxedo_log_files` should be defined as a dictionary of lists whose keys represent named groups of Tuxedo services (e.g. `cabs`, `ef`, `prod` or `scud`). Each list item represents one or more log files and requires the following parameters:

| Name                        | Default | Description                                                                           |
|-----------------------------|---------|---------------------------------------------------------------------------------------|
| `file_pattern`              |         | The log file name or a file name pattern to match against. Log files are assumed to reside in `/var/log/tuxedo/<service>` where `<service>` corresponds to the dictionary key under which the list item containing this parameter is defined. |
| `cloudwatch_log_group_name` |         | The name of the CloudWatch log group that will be used when pushing log data.         |
