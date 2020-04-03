timestamp := $(shell date -u +%FT%H-%MZ)
dh_repo := 'mecodia/python-base'

build:
	docker build --pull -t $(dh_repo):$(timestamp) -t $(dh_repo):latest .
push:
	docker push $(dh_repo):$(timestamp)
	docker push $(dh_repo):latest