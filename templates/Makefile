.PHONY: build clean dist instantiate install uninstall

ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD := $(ROOT_DIR)/build

JULIA ?= julia
JULIA_DIR := $(shell $(JULIA) --startup-file=no -e 'print(dirname(Sys.BINDIR))')
DLEXT := $(shell $(JULIA) --startup-file=no -e 'using Libdl; print(Libdl.dlext)')
VERSION := $(shell sed -n 's/^version *= *"\(.*\)"/\1/p' $(ROOT_DIR)/Project.toml)
OS := $(shell uname)
DEPS := $(shell find . build src -maxdepth 1 -and \( -name \*.toml -or -name \*.jl -or -name Makefile \) -and -not -type l)

NAME := {{{LIB}}}
NAME_VERSION := $(NAME)-$(VERSION)
_TAR_GZ := $(NAME_VERSION)-$(OS).tar.gz

DEST_DIR ?= $(NAME_VERSION)
DEST_BASENAME := $(shell basename $(DEST_DIR))
TAR_GZ := $(abspath $(DEST_DIR)/../$(_TAR_GZ))
OUT_DIR := $(DEST_DIR)/$(NAME)
BIN_DIR := $(OUT_DIR)/bin
INCLUDE_DIR = $(OUT_DIR)/include
LIB_DIR := $(OUT_DIR)/lib
PREFIX ?= $${HOME}/.local

LIB_NAME := lib$(NAME).$(DLEXT)
INCLUDES = $(INCLUDE_DIR)/julia_init.h $(INCLUDE_DIR)/$(NAME).h
LIB_PATH := $(LIB_DIR)/$(LIB_NAME)

.DEFAULT_GOAL := build

$(LIB_PATH) $(INCLUDES): $(BUILD)/build.jl $(DEPS)
	$(JULIA) --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
	$(JULIA) --startup-file=no --project=$(BUILD) -e 'using Pkg; Pkg.instantiate()'
	$(JULIA) --startup-file=no --project=$(BUILD) $< $(OUT_DIR)
# Replace the previous line with the line below to enable verbose debugging during package build
#	JULIA_DEBUG=PackageCompiler $(JULIA) --startup-file=no --project=$(BUILD) $< $(OUT_DIR)

build: $(LIB_PATH) $(INCLUDES) README.md $(BUILD)/INSTALL.txt $(BUILD)/install.sh
	cp README.md $(BUILD)/INSTALL.txt $(BUILD)/install.sh $(DEST_DIR)
	cd $(DEST_DIR) && ln -sf install.sh uninstall.sh

install: build
	cd $(DEST_DIR) && PREFIX=$(PREFIX) ./install.sh

uninstall: build
	cd $(DEST_DIR) && ./uninstall.sh

$(TAR_GZ): $(LIB_PATH) $(INCLUDES) Project.toml Manifest.toml $(BUILD)/*.jl $(BUILD)/*.toml
	cd $(DEST_DIR)/.. && tar -zcf $(TAR_GZ) \
		$(DEST_BASENAME)/README.md \
		$(DEST_BASENAME)/INSTALL.txt \
		$(DEST_BASENAME)/install.sh \
		$(DEST_BASENAME)/uninstall.sh \
		$(DEST_BASENAME)/$(NAME)

dist: $(TAR_GZ)

instantiate:
	$(JULIA) --startup-file=no --project=. -e "import Pkg; Pkg.instantiate()"
	$(JULIA) --startup-file=no --project=build -e "import Pkg; Pkg.instantiate()"

clean:
	$(RM) -Rf $(OUT_DIR)
