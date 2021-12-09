# fil-tuxedo-stack

This project encapsulates the infrastructure and deployment code for FIL Tuxedo services and includes separate branches for each:

* `infrastructure` - Infrastructure code for building FIL Tuxedo services in AWS
* `deployment` - Deployment code for deploying FIL Tuxedo services to AWS

The remainder of this document contains information that is specific to the branch in which it appears.

## Infrastructure

This branch (i.e. `deployment`) contains the deployment code responsible for deploying FIL Tuxedo services and is composed of multiple Ansible roles which are used primarily in CI to provision Informix database servers and deploy groups of FIL Tuxedo services to a given environment.

Refer to the documentation for each of the following roles for more information:

* [database](roles/database/README.md) - for provisioning Informix database server(s), dbspaces, chunks
* [deploy](roles/deploy/README.md) - for deploying FIL Tuxedo applications
