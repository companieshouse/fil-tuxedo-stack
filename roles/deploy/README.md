# Deploy role

This role implements a sequence of tasks required to deploy Tuxedo FIL services and configuration.

## Table of contents

* [Overview][1]
* [Configuration][2]
    * [Services][3]
        * [SMS service][4]
    * [Logging][5]
    * [Maintenance jobs][6]

[1]: #overview
[2]: #configuration
[3]: #services
[4]: #sms-service
[5]: #logging
[6]: #maintenance-jobs

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
| `informix_server_name`  |         | _Optional_. The name of the Informix server that services will access.                |

A `tuxedo_service_users` variable is required when running this role and can be provided using the `-e|--extra-vars` option to the `ansible-playbook` command. This variable should be defined as a list of group names to be deployed, where each group name corresponds to a key in the `tuxedo_service_config` configuration variable discussed above. For example, to deploy only services belonging to the `cabs` group:

```shell
ansible-playbook -i inventory --extra-vars='{"tuxedo_service_users": ["cabs"]}'
```

### SMS service

The following variables are used by the `SMS` service and `SMS_poll` daemon that are deployed for the `scud` user:

| Name                      | Default | Description                                                                           |
|---------------------------|---------|---------------------------------------------------------------------------------------|
| `sms_poll_daemon_enabled` | `false` | _Optional_. A boolean value indicating whether the `SMS_poll` daemon should be stopped before deployment and started again after deployment. |
| `sms_printer_name`        | `sms-printer` | The name of the printer to be used by the `SMS` service. A corresponding `SMS_PRINTER` environment variable should be set to the same value in the environment file for `scud` user services (see [fil-tuxedo-configs](https://github.com/companieshouse/fil-tuxedo-configs)). |
| `sms_printer_uri`         | `socket://172.19.33.138` | The URI of the printer to be used by the `SMS` service.              |
| `sms_printer_model`       | `drv:///sample.drv/generic.ppd` | A standard System V interface script or PPD file for the printer from the model directory or one of the driver interfaces. Use the `-m` option with the `lpinfo(8)` command to get a list of supported models. |

### Logging

Log data can be pushed to CloudWatch log groups automatically and is controlled by the `tuxedo_log_files` configuration variable. This variable functions in a manner similar to `tuxedo_service_config` (see [Services][3]), whereby each key represents the configuration for a named group of Tuxedo services, each of which corresponds to a user account on the remote host.

`tuxedo_log_files` should be defined as a dictionary of lists whose keys represent named groups of Tuxedo services (e.g. `cabs`, `ef`, `prod` or `scud`). Each list item represents one or more log files and requires the following parameters:

| Name                        | Default | Description                                                                           |
|-----------------------------|---------|---------------------------------------------------------------------------------------|
| `file_pattern`              |         | The log file name or a file name pattern to match against. Log files are assumed to reside in `/var/log/tuxedo/<service>` where `<service>` corresponds to the dictionary key under which the list item containing this parameter is defined. |
| `cloudwatch_log_group_name` |         | The name of the CloudWatch log group that will be used when pushing log data.         |


### Maintenance jobs

The `maintenance_jobs` variable can be used to configure scheduled maintenance jobs. This is used primarily as a group or host variable to configure maintenance jobs specific to environments or individual hosts and is generally limited to the _live_ environment where alerts and statistics are required. The absence of a group variable for a given environment means that _no_ scheduled jobs will be configured.

`maintenance_jobs` should be defined as a dictionary of lists whose keys represent named groups of Tuxedo services (e.g. `cabs`, `ef`, `prod` or `scud`). Each list item represents a single scheduled job for the user matching the dictionary key under which the item is defined. The following parameters are required for each list item:

| Name                 | Default | Description                                                                          |
|----------------------|---------|--------------------------------------------------------------------------------------|
| `name`               |         | A description of the job. This parameter should be unique across all jobs defined for a given group. |
| `day_of_week`        |         | Day of the week that the job should run (`0-6` for Sunday-Saturday, `*`, and so on). |
| `day_of_month`       |         | Day of the month the job should run (`1-31`, `*`, `*/2`, and so on).                 |
| `minute`             |         | Minute when the job should run (`0-59`, `*`, `*/2`, and so on).                      |
| `hour`               |         | Hour when the job should run (`0-23`, `*`, `*/2`, and so on).                        |
| `script`             |         | The name of the script to execute. This should correspond to a script that is present in the [fil-tuxedo-scripts](https://github.com/companieshouse/fil-tuxedo-scripts) artefact being used at the time the role is executed (i.e. the archive file whose path was provided with the `scripts_artifact_path` variable when executing `ansible-playbook`).

For example, to execute the `prod_stats` script at midnight every day as the `prod` user:

```yaml
maintenance_jobs:
  prod:
    - name: Server status alert
      day_of_week: "*"
      day_of_month: "*"
      minute: "0"
      hour: "0"
      script: "prod_stats"
```

During execution of this role, cron jobs are temporarily disabled to avoid generating false positive email alerts and are enabled again before completion of the role.

### Ephemeral data directories

The `ephemeral_data_dirs` variable can be used to create service-specific directories for the storage of short-lived files. This is used primarily as a group or host variable.

`ephemeral_data_dirs` should be defined as a dictionary of lists whose keys represent named groups of Tuxedo services (e.g. `cabs`, `ef`, `prod` or `scud`). Each list item represents a single directory for which the following parameters are required:

| Name                 | Default | Description                          |
|----------------------|---------|--------------------------------------|
| `name`               |         | The name of the directory to create. |

For example, to create a `fiche` directory for `scud` user services:

```yaml
ephemeral_data_dirs:
  scud:
    - name: fiche
```

The resulting directory will be created at the path `/home/scud/fiche` with `scud` user and group ownership and `0700` permissions.
