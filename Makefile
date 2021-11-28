ARCH               = $(or $(shell printenv ARCH),$(shell echo linux/amd64))
BUILD_FLAGS        = $(or $(shell printenv BUILD_FLAGS),--pull)
CREATED            = $(or $(shell printenv CREATED),$(shell date --rfc-3339=seconds))
DISTS              = $(or $(shell printenv DISTS),alpine debian ubuntu)
DIST               = $(or $(shell printenv DIST),alpine)
DOCKER_INTERACTIVE = $(if $(shell printenv GITHUB_ACTIONS),-t,-it)
GIT_REVISION       = $(or $(shell printenv GIT_REVISION), $(shell git describe --match= --always --abbrev=7 --dirty))
IMAGE              = $(or $(shell printenv IMAGE),cewood/rclone)
IMAGE_TAG          = $(or $(shell printenv IMAGE_TAG),${DIST}_${TAG_REVISION})
TAG_REVISION       = $(or $(shell printenv TAG_REVISION),${GIT_REVISION})



.PHONY: dists
dists: $(patsubst %,build-%,${DISTS})

.PHONY: alpine
alpine: build-alpine load-alpine dive-alpine
	$(MAKE) build-alpine TAG_REVISION=latest
	$(MAKE) load-alpine TAG_REVISION=latest

.PHONY: debian
debian: build-debian load-debian dive-debian
	$(MAKE) build-debian TAG_REVISION=latest
	$(MAKE) load-debian TAG_REVISION=latest

.PHONY: ubuntu
ubuntu: build-ubuntu load-ubuntu dive-ubuntu
	$(MAKE) build-ubuntu TAG_REVISION=latest
	$(MAKE) load-ubuntu TAG_REVISION=latest

.PHONY: build-%
build-%:
	$(MAKE) build DIST=$*

.PHONY: build
build:
	DOCKER_CLI_EXPERIMENTAL=enabled \
	docker \
	  buildx build \
	  ${BUILD_FLAGS} \
	  --build-arg CREATED="${CREATED}" \
	  --build-arg REVISION="${GIT_REVISION}" \
	  --platform ${ARCH} \
	  --tag ${IMAGE}:${IMAGE_TAG} \
	  -f Dockerfile-${DIST} \
	  .

.PHONY: load-%
load-%:
	$(MAKE) load DIST=$*

.PHONY: load
load:
	$(MAKE) build DIST=${DIST} BUILD_FLAGS=--load ARCH=linux/amd64

.PHONY: inspect
inspect:
	docker inspect ${IMAGE}:${IMAGE_TAG}

.PHONY: binfmt-setup
binfmt-setup:
	docker \
	  run \
	  --rm \
	  --privileged \
	  docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d

.PHONY: buildx-setup
buildx-setup: linuxkit-setup buildx-create

.PHONY: buildx-create
buildx-create:
	DOCKER_CLI_EXPERIMENTAL=enabled \
	docker \
	  buildx \
	  create \
	  --use \
	  --node multiarch0 \
	  --name multiarch

.PHONY: linuxkit-setup
linuxkit-setup:
	docker \
	  run \
	  --rm \
	  --privileged \
	  tonistiigi/binfmt:qemu-v6.1.0

.PHONY: dive-%
dive-%:
	$(MAKE) dive DIST=$*

.PHONY: dive
dive:
	docker run --rm -it \
	  -e CI=true \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  wagoodman/dive:v0.9.2 ${IMAGE}:${IMAGE_TAG}

.PHONY: ci
ci:
	$(MAKE) dists BUILD_FLAGS=$(if $(findstring tags,${GITHUB_REF}),--push,--pull)
	$(MAKE) dists BUILD_FLAGS=$(if $(findstring tags,${GITHUB_REF}),--push,--pull) TAG_REVISION=latest
