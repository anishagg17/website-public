WormBase Website Repository
===========================

This repository contains the [WormBase](http://www.wormbase.org) Web application.

**The repository for [WormBase Mobile](http://m.wormbase.org) can be found at [WormBase/website-mobile](https://github.com/WormBase/website-mobile)**

Technical Overview
------------------

The technical stack of WormBase website consits of:
- A web server based on a MVC framework, [Catalyst](http://www.catalystframework.org/) and [Template Toolkit](http://www.template-toolkit.org/)
- React for some portions of the UI
- Database engines: ACeDB, MySQL, Datomic
- Nginx
- BLAST, and other bioinformatics tools
- [A RESTful data API](https://github.com/WormBase/wormbase_rest)
- [A RESTful search API](https://github.com/WormBase/wb-search)

For devOps, we use Docker, docker-compose, Jenkins, AWS Elastic Beanstalk.


Development
--------------------------------------------------------

Development environment can be setup easily and without installing any dependency, using a shared development machine and `docker-compose`.

_For Legacy instructions_ that set up without docker or docker-compose, please visit the [Manual Setup Guide](/docs/manual_setup.md).

**Prerequisite:**

- Obtain access and login to the shared development instance, where data and legacy software are stored.

- Ensure environment variable `CATALYST_PORT` and `WEBPACK_SERVER_PORT` are set.

- Ensure `/usr/local/bin/` is on your $PATH, as dependencies such as `docker-compose` and `yarn` are installed there.

**To start your development stack:**

`make dev` and wait for website/Catalyst and webpack(DevServer) to start.

**To shutdown your development stack cleanly:**

`make dev-down`


### Development Environment Troubleshooting

**`make dev` appears stuck**

The first time that `make dev` runs, it takes longer due to installation of dependencies.

**The stdout is jumbled**

The `stdout` of docker-compose combines the stdouts of the containers. To make it easier to read, stdout of individual containers can be accessed via `SERVICE=[name_of_service] make console`, where the name of service could be website, webpack, etc as found in [docker-compose.yml](docker-compose.yml) and [docker-compose.dev.yml](docker-compose.dev.yml).

**`docker-compose` cli commands not taking effect**

The Makefile exports user-specific environment variable `COMPOSE_PROJECT_NAME` to allow multiple instances of the development stack to run on the same machine. If you use docker-compose cli directly, please set `COMPOSE_PROJECT_NAME` accordingly to interact with your particular development instance.

**Unable to connect to ACeDB**

ACeDB container isn't started as part the development stack to reduce memory footprint. Instead, we rely on a shared acedb container, by joining the docker networked called `wb-network` where the acedb runs on. If the shared acedb container is down, instructions to start the shared acedb container is found [here](https://github.com/WormBase/wormbase-architecture/blob/develop/roles/acedb/files/startserver.sh).

**Prettier git pre-commit hook doesn't trigger**

JavaScript dependencies are installed both on the host and in the container. The former is necessary to enable code formatting with Prettier and git pre-commit hooks with Husky.


Staging Environment
---------------------------------------------

WormBase staging site is hosted on the shared development instance. Its deployment is automated, triggered by committing to the staging branch on Github.

Continuous integration for staging environment is handled by Jenkins. Jenkins runs the [jenkins-ci-deploy.sh](jenkins-ci-deploy.sh) script to for deployment and testing. For detailed setup, please visit the Jenkins web console.

Production Environment
---------------------------------------------

WormBase production site is hosted with AWS Elastic Beanstalk. For details about customizing the production deployment, please visit the [WormBase Beanstalk Guide](docs/beanstalk.md).

### Prepare for a website release

- Change the WS release number in wormbase.conf, in particular, `wormbase_release`, `rest_server`, and `search_server` properties
- Create the release branch, such as `release/273`
- At the release branch:

  ```console
  make release  # to build the assets (ie containers) required for deployment
  ```

  ```console
  make eb-create  # to create and deploy to the pre-production environment
  ```

- Login to the AWS Management Console, and navigate to Elastic Beanstalk, and then to the `website` Application.
    - Wait for the deployment to complete, and verify the pre-production environment is working
        - **If ACeDB TreeView isn't working**, which seems to be caused by a race condition between setting up the file system and starting ACeDB container, the problem can be fixed by re-deploying to the same environment `make production-deploy`.
    - Swap the URL between the pre-production environment and the current production environment
    - After making sure the new production environment is working, wait until the DNS TTL passes on Nginx before shutting down the previous production environment




### Apply Hotfix on AWS ElasticBeanstalk

- Prior to applying the hotfix, ensure you are at the appropriate git branch for production.

- Then run the following commands,

	```console
	VERSION=[GIT_TAG_TO_BE_CREATED] make release  # the tag should look like WS268.12
	make production-deploy
	```

### Production Deployment without AWS Beanstalk

For instances not managed by Beanstalk, deployment can be performed with:

```console
# ensure port 5000 is available, then
make production-deploy-no-eb
```

Contributing
------------

Our development workflow can be found here:

[http://wiki.wormbase.org/index.php/Development_workflow_-_webdev](http://wiki.wormbase.org/index.php/Development_workflow_-_webdev)

Todd Harris (todd@wormbase.org)

Acknowledgements
----------------

<a href="https://www.browserstack.com/"><img src="https://www.browserstack.com/images/mail/browserstack-logo-footer.png" alt="BrowserStack" width="120px" /></a>

Thanks to BrowserStack for allowing us to perform interactive cross browser and cross OS testing.
