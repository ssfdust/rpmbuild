.PHONY: help clean
.DEFAULT: help
ifndef VERBOSE
.SILENT:
endif

NO_COLOR=\033[0m
GREEN=\033[32;01m
YELLOW=\033[33;01m
RED=\033[31;01m

SHELL = bash
CWD := $(shell pwd -P)
BUILD_NUMBER ?= 0
#RELEASE ?= $(BUILD_NUMBER)
# Use commit/author date remotely
SPEC_DATE := $(shell git log -1 --format=%ct *.spec)
ifndef SPEC_DATE
    EPOCH := 0
else
    EPOCH := $(shell expr `date +%s` - $(SPEC_DATE))
endif
RELEASE ?= $(EPOCH)
SPEC_VER := $(shell rpm -q --queryformat="%{version}\n" --specfile *.spec | head -n 1)
VERSION ?= $(SPEC_VER)
DONE = echo -e "\e[31m✓\e[0m \e[33m$@\e[0m \e[32mdone\e[0m"
distro ?= centos7

ifneq ($(and $(BUILD_NUMBER),$(WORKSPACE),$(JENKINS_URL)),)
    BUILD_ENVIRONMENT = jenkins-ci
endif

SYS_ID_U := $(shell id -u)
ID_U ?= $(SYS_ID_U)
SYS_ID_G := $(shell id -g)
ID_G ?= $(SYS_ID_G)

ifeq ($(BUILD_ENVIRONMENT),jenkins-ci)
    DOCKER := docker
    DOCKER_OPTS := -i #-u $(ID_U)
    #DOCKER_OPTS := -i
    #COMMAND_OPTS := groupadd builder2 -g $(ID_G) || true; useradd builder2 -u $(ID_U) -g builder || true;
else
    DOCKER := docker
    DOCKER_OPTS := -it #-u $(ID_U)
endif
DOCKER_NET := --network host

ifdef SELINUX
    MOUNT = $(CURDIR):/src:Z
else
    MOUNT = $(CURDIR):/src
endif

#PKG_NAME := $(shell rpm -q --queryformat="%{name}-%{version}-%{release}.%{arch}\n" --specfile *.spec --define "_release $(RELEASE)"| head -n 1)
PKG_NAME := $(shell rpm -q --queryformat="%{name}\n" --specfile *.spec --define "_release $(RELEASE)"| head -n 1)
#PKG_VER := $(shell rpm -q --queryformat="%{version}-%{release}\n" --specfile *.spec --define "_release $(RELEASE)"| head -n 1)
#BUILD_DEFS := --define '_rpmdir $(CURDIR)/pkg' --define '_release $(RELEASE)'
#BUILD_OPTS := -ba --define "_sourcedir $(CURDIR)" $(BUILD_DEFS)
BUILD_DIR := pkg
SPECS := $(wildcard *.spec)
RPMS := $(patsubst %.spec,$(BUILD_DIR)/%-*.rpm,$(SPECS))
export RPM_BUILD_NCPUS := 8
REGISTRY ?= "mbevc1"
IMG_NAME := $(REGISTRY)/rpmbuild

help:: ## Show this help
	echo -e "\n$(NAME) packaging: Version \033[32m$(VERSION)-$(RELEASE)\033[0m Package: \033[34m$(PKG_NAME)\033[0m\n"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: rpmbuild
docker-build: docker-image ## Build RPM using container
ifndef SPEC
	@echo -e "$(YELLOW)==>$(NO_COLOR) Missing $(RED)SPEC$(NO_COLOR) variable. $(NO_COLOR)\n"; exit 1;
endif
	echo -e "==> $(GREEN)Start Docker rpmbuild using $(SPEC) | distro=$(distro)$(NO_COLOR)"
	$(DOCKER) run --rm $(DOCKER_OPTS) -v $(MOUNT) \
            -e VERBOSE=0 \
            -e VERSION=$(VERSION) \
            -e RELEASE=$(RELEASE) \
	    $(DOCKER_NET) \
	    $(IMG_NAME) \
	    $(SPEC) $(BUILD_DIR)
	echo -e "==> $(GREEN)Produced artefact $(RED)$(PKG_NAME)-$(VERSION)-$(RELEASE)$(GREEN) in $(YELLOW)pkg/$(GREEN) folder$(NO_COLOR)"
	$(MAKE) docker-clean
	$(DONE)

.PHONY: build
build: $(RPMS) ## Build RPM

$(BUILD_DIR)/%-*.rpm: %.spec
	echo -e "==> $(GREEN)Building RPM package using $<$(NO_COLOR)"
	#rpmbuild $< $(BUILD_OPTS)
	$(MAKE) docker-build SPEC=$<
	$(DONE)

.PHONY: clean
clean: ## Clean up artefacts
	echo -e "==> $(YELLOW)Cleaning up packaging artefacts$(NO_COLOR)"
	-rm -rf pkg
	$(DONE)

.PHONY: docker-clean
docker-clean: ## Clean Docker artefacts
	echo -e "==> $(GREEN)Clean Docker artefacts$(NO_COLOR)"
	-$(DOCKER) container prune -f
	-$(DOCKER) volume prune -f
	-$(DOCKER) image prune -f
	$(DONE)

.PHONY: docker-pull
docker-pull: ## Update Docker image from repository
	echo -e "==> $(GREEN)Update Docker image $(IMG_NAME) from registry$(NO_COLOR)"
	$(DOCKER) pull $(IMG_NAME)
	$(DONE)

.PHONY: docker-image
docker-image: ## Build Docker image
	echo -e "==> $(GREEN)Build Docker image $(IMG_NAME) for $(distro) as UID=$(ID_U)|GID=$(ID_G)$(NO_COLOR)"
	$(DOCKER) build --pull --force-rm $(DOCKER_NET) \
	    --build-arg OS_RELEASE=7 \
	    --build-arg UID=$(ID_U)1 \
	    --build-arg GID=$(ID_G)1 \
	    -f Dockerfile -t $(IMG_NAME) \
	    .
	$(MAKE) docker-clean
	$(DONE)

.PHONY: docker-rmi
docker-rmi: ## Clean Docker image
	echo -e "==> $(YELLOW)Removing Docker image $(IMG_NAME)$(NO_COLOR)"
	$(DOCKER) rmi $(IMG_NAME)
	$(DONE)
