FROM alpine:3.15 as uwsgi_builder
WORKDIR /tmp/build

RUN apk add --no-cache uwsgi=~2.0 uwsgi-python3 gcc linux-headers musl-dev libcap-dev openssl-dev pcre-dev zlib-dev && \
    # Link python3 and pip3 to default python and pip
    ln -fs /usr/bin/python3.9 /usr/bin/python && ln -fs /usr/bin/pip3 /usr/bin/pip 
ADD https://raw.githubusercontent.com/velebit-ai/uwsgi-json-logging-plugin/master/escape_json.c escape_json.c
RUN uwsgi --build-plugin escape_json.c


FROM alpine:3.15 as base

# Add generic wait-for-postgres command
COPY wait-for-postgres.sh /usr/local/bin/wait-for-postgres

# Add default uwsgi configuration
COPY uwsgi.ini /etc/uwsgi_defaults.ini

# Add up to date uwsgidecorators to python
ADD https://raw.githubusercontent.com/unbit/uwsgi/2.0.20/uwsgidecorators.py /usr/lib/python3.9/uwsgidecorators.py

# Install uwsgi and needed plugins
RUN apk add --no-cache uwsgi=~2.0 uwsgi-python3 uwsgi-spooler uwsgi-cache uwsgi-logfile\
    # Install python3.9 and pip from the alpine repository, since they provide it in alpine 3.11+
    # This is good enough for us and enables us to install precompiled packages from apk
    python3=~3.9 py3-pip py3-wheel\
    # Install postgres client for the wait-for-postgres script
    postgresql13-client=~13 && \
    # Link python3 and pip3 to default python and pip
    ln -fs /usr/bin/python3.9 /usr/bin/python && ln -fs /usr/bin/pip3 /usr/bin/pip && \
    # Make the copied files execuable and readable for all
    chmod 755 /usr/local/bin/wait-for-postgres && \
    chmod 655 /usr/lib/python3.9/uwsgidecorators.py && \
    # Install and build psycopg2-binary and psycopg2, so it does not matter which one a package has in requirements.
    apk add --no-cache --virtual build-deps gcc python3-dev postgresql-dev musl-dev && \
    pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir psycopg2-binary psycopg2 && \
    apk del build-deps && \
    # Add a user and a group to use for execution so we follow best practices
    addgroup -S mecodia && adduser -S mecodia -G mecodia

# Copy built uwsgi plugin from other stage
COPY --from=uwsgi_builder /tmp/build/escape_json_plugin.so /usr/lib/uwsgi/

# Tell uwsgi to load defaults
ENV UWSGI_INI=/etc/uwsgi_defaults.ini

WORKDIR /home/mecodia
ENTRYPOINT ["uwsgi"]

# Here the real magic happens
# This is run if somebody FROMs this image.
# Set a GIT_BUILD_VERSION so we can identify this image from within the container by setting a ENV Var
ONBUILD ARG GIT_BUILD_VERSION=unknown
ONBUILD ENV GIT_BUILD_VERSION=$GIT_BUILD_VERSION
# Copy everything in the Dockerfile folder into this image
# Use the .dockerignore to exclude files from being copied
ONBUILD COPY .build /home/mecodia/.build
ONBUILD COPY setup.py /home/mecodia
# Install additional packages we need, like image libaries
ONBUILD RUN apk add --no-cache $(cat .build/runtime-packages.txt | sed -e ':a;N;$!ba;s/\n/ /g') && \
            # Install packages we need to install a python packages that needs to be compiled. These will be deleted afterwards.
            apk add --no-cache --virtual build-deps gcc python3-dev musl-dev $(cat .build/build-packages.txt | sed -e ':a;N;$!ba;s/\n/ /g') && \
            # Install the current folder as editable so we have it on the pythonpath but don't need to actually package it
            pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -e . && \
            # Remove build packages and chown everything in here for our user
            apk del build-deps && chown -R mecodia:mecodia .
# Run everything afterwards as the mecodia user
ONBUILD COPY . /home/mecodia
ONBUILD USER mecodia
