FROM alpine:3.11

# Add generic wait-for-postgres command
COPY wait-for-postgres.sh /usr/local/bin/wait-for-postgres

# Add up to date uwsgidecorators to python
ADD https://raw.githubusercontent.com/unbit/uwsgi/2.0.18/uwsgidecorators.py /usr/lib/python3.8/uwsgidecorators.py

    # Install uwsgi and needed plugins
RUN apk add --no-cache uwsgi=~2.0.18 uwsgi-python3 uwsgi-spooler uwsgi-cache \
    python3=~3.8 py3-pip \
    postgresql-client=~12 && \
    # Link some packages and chmod some files
    ln -s /usr/bin/python3.8 /usr/bin/python && ln -s /usr/bin/pip3 /usr/bin/pip && \
    chmod 755 /usr/local/bin/wait-for-postgres && \
    chmod 655 /usr/lib/python3.8/uwsgidecorators.py && \
    # Install and build psycopg2-binary and psycopg2
    apk add --no-cache --virtual build-deps gcc python3-dev postgresql-dev musl-dev && \
    pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir psycopg2-binary psycopg2 && \
    apk del build-deps && \
    # Add a user so we are more secure
    addgroup -S mecodia && adduser -S mecodia -G mecodia

WORKDIR /home/mecodia
ENV UWSGI_STRICT=1 \
    UWSGI_MASTER=1 \
    UWSGI_WORKERS=2 \
    UWSGI_ENABLE_THREADS=1 \
    UWSGI_VACUUM=1 \
    UWSGI_SINGLE_INTERPRETER=1 \
    UWSGI_DIE_ON_TERM=1 \
    UWSGI_NEED_APP=1 \
    UWSGI_MAX_REQUESTS=10000 \
    UWSGI_MAX_WORKER_LIFETIME=86400 \
    UWSGI_RELOAD_ON_RSS=512 \
    UWSGI_WORKER_RELOAD_MERCY=60 \
    UWSGI_PLUGINS=python3,spooler,cache

ONBUILD ARG GIT_BUILD_VERSION=unknown
ONBUILD ENV GIT_BUILD_VERSION=$GIT_BUILD_VERSION
ONBUILD COPY . /home/mecodia
ONBUILD RUN apk add --no-cache $(cat .build/runtime-packages.txt | sed -e ':a;N;$!ba;s/\n/ /g') && \
            apk add --no-cache --virtual build-deps gcc python3-dev musl-dev $(cat .build/build-packages.txt | sed -e ':a;N;$!ba;s/\n/ /g') && \
            pip install --no-cache-dir -e . && \
            apk del build-deps && chown -R mecodia:mecodia .
ONBUILD USER mecodia
