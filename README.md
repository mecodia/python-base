# Docker Base Image for mecodia GmbH Django Projects

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mecodia/python-base/latest)](https://hub.docker.com/r/mecodia/python-base)

This image was specifically crafted to be as small as possible while also giving a good basic packaging.
We are trying to follow the best practices of Docker and Kubernetes with this image to improve speed and security.

## Features

This image is based on alpine linux and provides the following features:

- Python 3.x
- uwsgi with python3, spooler and cache plugin loaded and sane default settings
- pyscop2 and pyscop2-binary
- wait-for-postgres command (wait for the DB defined in \$POSTGRES_HOST)
- Possibility to add additional packages and build-only packages

## How to use

This images is intended to be used with a standard python3.x and django2.x project.

The project structure should look roughly like this:

    .
    ├── .dockerignore
    ├── .git/
    ├── .gitignore
    ├── Makefile
    ├── README.md
    ├── docker-compose.yml
    └── project
        ├── .build
        │   └── runtime-packackes.txt
        │   └── build-packages.txt
        ├── myproject
        │   ├── __init__.py
        │   ├── apps
        │   ├── settings
        │   ├── static
        │   ├── templates
        │   ├── urls.py
        │   └── wsgi.py
        ├── Dockerfile
        ├── init.sh
        ├── test.sh
        └── setup.py

The corresponding dockerfile in the subproject using this base image can be as close to zero as:

    FROM mecodia/python-base:latest

    ENV POSTGRES_HOST db.example.com
    RUN mkdir -p var/static

The image should be ran with the following command as the bare minimum:

    uwsgi --http-socket 0.0.0.0:8000 --module myproject.wsgi:application --show-config

or if we use a prerun script:

    sh ./init.sh uwsgi --http-socket 0.0.0.0:8000 --module myproject.wsgi:application --show-config

## Release Process

Edit and use the `build.sh` script to push a new image tag to docker hub.
