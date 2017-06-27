IMAGE_NAME=oconnormi/ddf-base
GIT_BRANCH:=$(shell git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,' 2>/dev/null)
ifneq (${GIT_BRANCH}, master)
	IMAGE_TAG=${GIT_BRANCH}
else
	IMAGE_TAG=latest
endif

.PHONY: build

build:
	docker build -t ${IMAGE_NAME}:alpine-${IMAGE_TAG} -f linux/alpine/Dockerfile linux/
	docker tag ${IMAGE_NAME}:alpine-${IMAGE_TAG} ${IMAGE_NAME}:${IMAGE_TAG}
	docker build -t ${IMAGE_NAME}:centos-${IMAGE_TAG} -f linux/centos/Dockerfile linux/

deploy: build
	docker push ${IMAGE_NAME}:${IMAGE_TAG}
	docker push ${IMAGE_NAME}:alpine-${IMAGE_TAG}
	docker push ${IMAGE_NAME}:centos-${IMAGE_TAG}
