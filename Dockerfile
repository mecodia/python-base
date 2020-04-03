FROM python:3.8-alpine

COPY wait-for-postgres.sh /usr/local/bin/wait-for-postgres

ADD https://raw.githubusercontent.com/unbit/uwsgi/master/uwsgidecorators.py /usr/local/lib/python3.8/uwsgidecorators.py

RUN apk add --no-cache uwsgi uwsgi-python3 postgresql-client postgresql-dev && \
    apk add --no-cache --virtual build-deps gcc python3-dev musl-dev && \
    pip install psycopg2-binary psycopg2 && \
    apk del build-deps && \
    addgroup -S mecodia && adduser -S mecodia -G mecodia && \
    chmod 755 /usr/local/bin/wait-for-postgres && \
    chmod 655 /usr/local/lib/python3.8/uwsgidecorators.py

WORKDIR /home/mecodia
USER mecodia
ENV PATH=/home/mecodia/.local/bin:$PATH \
    UWSGI_STRICT=1 \
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
    UWSGI_PLUGINS=python