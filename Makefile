.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

ROOT_DIR := $(CURDIR)
SKILLS_REF_INSTALLER := ./scripts/install-skills-ref.sh
SKILLS_VALIDATOR := ./scripts/validate-skills.sh
LEFTHOOK_BIN := $(shell command -v lefthook 2>/dev/null || true)
BREW_BIN := $(shell command -v brew 2>/dev/null || true)

.PHONY: help install-skills-ref validate validate-skills hooks-install hooks-run ci-validate

help:
	@printf '%s\n' \
	  'Available targets:' \
	  '  make install-skills-ref  Install pinned skills-ref locally into .tools/' \
	  '  make validate            Validate all skills with skills-ref and repo checks' \
	  '  make validate-skills     Alias for validate' \
	  '  make hooks-install       Install Lefthook and sync repo hooks' \
	  '  make hooks-run           Run the same validation used by the pre-push hook' \
	  '  make ci-validate         Run the CI-equivalent repository validation'

install-skills-ref:
	@$(SKILLS_REF_INSTALLER)

validate: validate-skills

validate-skills:
	@$(SKILLS_VALIDATOR)

hooks-install:
	@if [ -z "$(LEFTHOOK_BIN)" ]; then \
	  if [ -n "$(BREW_BIN)" ]; then \
	    echo '[INFO] Installing Lefthook with Homebrew'; \
	    $(BREW_BIN) install lefthook; \
	  else \
	    echo '[FAIL] Lefthook is not installed and Homebrew is unavailable.' >&2; \
	    exit 1; \
	  fi; \
	fi
	@"$$(command -v lefthook || printf '%s' "$(shell [ -n "$(BREW_BIN)" ] && printf '%s/bin/lefthook' "$$(brew --prefix)"))" install

hooks-run:
	@$(SKILLS_VALIDATOR)

ci-validate:
	@$(SKILLS_VALIDATOR)
