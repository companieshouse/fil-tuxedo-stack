# fil-tuxedo-stack

This project encapsulates the infrastructure and deployment code for FIL Tuxedo services and includes separate branches for each:

* `infrastructure` - Infrastructure code for building FIL Tuxedo services in AWS
* `deployment` - Deployment code for deploying FIL Tuxedo services to AWS

The remainder of this document contains information that is specific to the branch in which it appears.

## Deployment

This branch (i.e. `deployment`) contains the deployment code responsible for deploying FIL Tuxedo services and contains several Ansible playbooks which are used in CI/CD pipelines to provision servers in AWS:

- [database.yml](database.yml) - provision Informix database server(s), dbspaces, and chunks
- [deploy.yml](deploy.yml) - deploy application services and configs
- [devices.yml](devices.yml) - discover and configure iSCSI devices
- [management.yml](management.yml) - deploy Informix cron jobs and management tools
- [nfs.yml](nfs.yml) - configure and mount persistent NFS shares
