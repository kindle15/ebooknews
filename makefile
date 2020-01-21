#
# Simple build environment
#

#
# print colored output
RESET_COLOR    = \033[0m
make_std_color = \033[3$1m      # defined for 1 through 7
make_color     = \033[38;5;$1m  # defined for 1 through 255
OK_COLOR       = $(strip $(call make_std_color,2))
WRN_COLOR      = $(strip $(call make_std_color,3))
ERR_COLOR      = $(strip $(call make_std_color,1))
STD_COLOR      = $(strip $(call make_color,8))

COLOR_OUTPUT = 2>&1 |                                        \
    while IFS='' read -r line; do                            \
        if  [[ $$line == FAIL* ]]; then                      \
            echo -e "$(ERR_COLOR)$${line}$(RESETCOLOR)";     \
        elif [[ $$line == *:[\ ]FAIL:* ]]; then              \
            echo -e "$(ERR_COLOR)$${line}$(RESETCOLOR)";     \
        elif [[ $$line == [\-][\-][\-][\ ]FAIL:* ]]; then    \
            echo -e "$(ERR_COLOR)$${line}$(RESETCOLOR)";     \
        elif [[ $$line == WARN* ]]; then                     \
            echo -e "$(WRN_COLOR)$${line}$(RESET_COLOR)";    \
        elif [[ $$line == PASS ]]; then                       \
            echo -e "$(OK_COLOR)$${line}$(RESET_COLOR)";     \
        elif [[ $$line == [\-][\-][\-][\ ]PASS:* ]]; then    \
            echo -e "$(OK_COLOR)$${line}$(RESETCOLOR)";     \
        elif [[ $$line == ok* ]]; then                       \
            echo -e "$(OK_COLOR)$${line}$(RESET_COLOR)";     \
        else                                                 \
            echo -e "$(STD_COLOR)$${line}$(RESET_COLOR)";    \
        fi;                                                  \
    done; exit $${PIPESTATUS[0]};

.DEFAULT: $(help)

SHELL           := /bin/bash
CUR_DIR         := $(shell pwd)

CLEAN_FILES 		:=   \
					$(wildcard ./docker/target/recipes/cover*.*)  \
					$(wildcard ./tmp/*)  \
					$(wildcard ./docker/target/tmp/*)  \
					$(wildcard ./build/*)  \
					$(wildcard ./release/*)

ARTEFACT_NAME 	:= calibre-tools-$(shell printf "%s%s" `cat ./version.raw` `git rev-parse --short HEAD`)
REMOTE_ADDR     := bilbo_deploy # defined in .ssh/config
REMOTE_SERVICE	:= services/ebooknews
REMOTE_TARGET		:= bilbo_deploy:services/ebooknews
#REMOTE_TARGET		:= $(shell echo "$(REMOTE_ADDR)$:$(REMOTE_SERVICE)")

help:
	-@echo "Makefile with following options (make <option>):"
	-@echo "	clean"
	-@echo "	build_image"
	-@echo "	build"
	-@echo "	release"
	-@echo "	deploy"
	-@echo "    (*) not implemented"
	-@echo ""

clean:
	rm -rf $(CLEAN_FILES)

build_image:
	@docker build -f docker/dockerfile -t brutus/calibre ./docker

build: clean build_image
	@mkdir -p ./build
	@docker save --output ./build/calibre-tools.tar brutus/calibre
	@cp -r ./cronjob ./build/.
	@cp -r ./scripts ./build/.
	@cp -r ./docker/target ./build/.
	@cp ./README.md ./build/.
	@cp ./docker/docker-compose.prod.nas.yml ./build/.
	@echo ""
	@echo "ok" $(COLOR_OUTPUT)
	@echo ""

release: build
	@echo "Collect artifacts for release"
	@sed 's/@@@ARTEFACT_NAME@@@/${ARTEFACT_NAME}/g' ./build/scripts/install.sh > ./build/scripts/install_$(ARTEFACT_NAME).sh
	@rm ./build/scripts/install.sh
	@mkdir -p ./release
	@printf "%s%s" `cat ./version.raw` `git rev-parse --short HEAD` > ./build/version 
	@tar --format=gnu -czvf ./release/$(ARTEFACT_NAME).tar.gz ./build
	@echo "Build release done. See ./release/$(ARTEFACT_NAME).tag.gz"
	@echo ""
	@echo "ok" $(COLOR_OUTPUT)
	@echo ""

deploy:	
	@echo "Deploy to remote service"
	@echo "From: ./release/$(ARTEFACT_NAME).tar.gz"
	@echo "To  : $(REMOTE_TARGET)/releases"
	@scp ./release/$(ARTEFACT_NAME).tar.gz $(REMOTE_TARGET)/releases
	@echo "From: ./build/scripts/install_$(ARTEFACT_NAME).sh"
	@echo "To  : $(REMOTE_TARGET)/releases"
	@scp ./build/scripts/install_$(ARTEFACT_NAME).sh $(REMOTE_TARGET)/releases
	@echo "Execute  : ssh $(REMOTE_ADDR) $(REMOTE_SERVICE)/releases/install_$(ARTEFACT_NAME).sh"
	@ssh $(REMOTE_ADDR) $(REMOTE_SERVICE)/releases/install_$(ARTEFACT_NAME).sh
	@echo "deploy done"
	@echo ""
	@echo "ok" $(COLOR_OUTPUT)
	@echo ""

# EOF