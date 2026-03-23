# Makefile for Pyan3 development and demos
#
# Notes:
# - Activation cannot persist across separate make targets/shells.
# - Use `make activate-linux` or `make activate-windows` to print the command
#   you can run manually in your current terminal.

.PHONY: help bootstrap venv install install-dev install-test install-all upgrade-pip \
        uv-check uv-sync uv-sync-test uv-sync-dev uv-sync-all uv-lint uv-test uv-coverage uv-run \
        activate-linux activate-windows which-python check graphviz-check \
        lint test test-quick coverage check demo demo-callgraph demo-modulegraph demo-text demo-paths \
        clean clean-demo clean-venv

VENV_DIR ?= .venv
DEMO_DIR ?= demo_out
PYTHON_BIN ?= python
PIP_FLAGS ?=
UV_BIN ?= uv

ifeq ($(OS),Windows_NT)
	VENV_PYTHON := $(VENV_DIR)/Scripts/python.exe
	VENV_PIP := $(VENV_DIR)/Scripts/pip.exe
	VENV_ACTIVATE := $(VENV_DIR)\Scripts\activate
	RM_RF := if exist "$(1)" rmdir /S /Q "$(1)"
	MKDIR_P := if not exist "$(1)" mkdir "$(1)"
else
	VENV_PYTHON := $(VENV_DIR)/bin/python
	VENV_PIP := $(VENV_DIR)/bin/pip
	VENV_ACTIVATE := source $(VENV_DIR)/bin/activate
	RM_RF := rm -rf "$(1)"
	MKDIR_P := mkdir -p "$(1)"
endif

help:
	@echo "Pyan3 Make targets"
	@echo "  make bootstrap        - create venv + install editable package with dev/test/sphinx extras"
	@echo "  make venv             - create virtual environment only"
	@echo "  make install          - install package (editable)"
	@echo "  make install-dev      - install dev extras"
	@echo "  make install-test     - install test extras"
	@echo "  make install-all      - install dev + test + sphinx extras"
	@echo "  make test             - run full test suite"
	@echo "  make lint             - run ruff lint checks"
	@echo "  make coverage         - run tests with coverage"
	@echo "  make check            - run lint + test"
	@echo "  make demo             - generate demo artifacts in $(DEMO_DIR)/"
	@echo "  make clean            - remove caches and generated files"
	@echo "  make clean-demo       - remove demo artifacts only"
	@echo "  make clean-venv       - remove virtual environment only"
	@echo "  make activate-linux   - print Linux/macOS activation command"
	@echo "  make activate-windows - print Windows activation command"
	@echo ""
	@echo "uv-based workflow targets (recommended by repo docs):"
	@echo "  make uv-check         - show uv version"
	@echo "  make uv-sync          - uv sync (base deps)"
	@echo "  make uv-sync-test     - uv sync --extra test"
	@echo "  make uv-sync-dev      - uv sync --extra dev"
	@echo "  make uv-sync-all      - uv sync --extra dev --extra test --extra sphinx"
	@echo "  make uv-lint          - uv run ruff check ."
	@echo "  make uv-test          - uv run pytest tests/ -v"
	@echo "  make uv-coverage      - uv run pytest with coverage"
	@echo "  make uv-run ARGS='--help' - run pyan3 via uv"

bootstrap: venv install-all

venv:
	$(PYTHON_BIN) -m venv $(VENV_DIR)
	$(VENV_PYTHON) -m pip install --upgrade pip setuptools wheel

upgrade-pip:
	$(VENV_PYTHON) -m pip install --upgrade pip setuptools wheel

install: venv
	$(VENV_PIP) install $(PIP_FLAGS) -e .

install-dev: venv
	$(VENV_PIP) install $(PIP_FLAGS) -e ".[dev]"

install-test: venv
	$(VENV_PIP) install $(PIP_FLAGS) -e ".[test]"

install-all: venv
	$(VENV_PIP) install $(PIP_FLAGS) -e ".[dev,test,sphinx]"

uv-check:
	$(UV_BIN) --version

uv-sync:
	$(UV_BIN) sync

uv-sync-test:
	$(UV_BIN) sync --extra test

uv-sync-dev:
	$(UV_BIN) sync --extra dev

uv-sync-all:
	$(UV_BIN) sync --extra dev --extra test --extra sphinx

uv-lint:
	$(UV_BIN) run ruff check .

uv-test:
	$(UV_BIN) run pytest tests/ -v

uv-coverage:
	$(UV_BIN) run pytest tests/ --cov=pyan --cov-branch --cov-report=term-missing

uv-run:
	$(UV_BIN) run pyan3 $(ARGS)

activate-linux:
	@echo "Run this in your shell:"
	@echo "  source $(VENV_DIR)/bin/activate"

activate-windows:
	@echo "Run one of these in your shell:"
	@echo "  PowerShell: .\\$(VENV_DIR)\\Scripts\\Activate.ps1"
	@echo "  CMD:        .\\$(VENV_DIR)\\Scripts\\activate.bat"

which-python:
	@echo "Using interpreter: $(VENV_PYTHON)"
	@$(VENV_PYTHON) --version

check: lint test

lint:
	$(VENV_PYTHON) -m ruff check .

test:
	$(VENV_PYTHON) -m pytest tests/ -v

test-quick:
	$(VENV_PYTHON) -m pytest tests/test_features.py tests/test_modvis.py -v

coverage:
	$(VENV_PYTHON) -m pytest tests/ --cov=pyan --cov-branch --cov-report=term-missing

graphviz-check:
	@dot -V

demo: demo-callgraph demo-modulegraph demo-text demo-paths

demo-callgraph: install-test
	$(call MKDIR_P,$(DEMO_DIR))
	$(VENV_PYTHON) -m pyan.main tests/orbital/*.py --dot --colored --no-defines --concentrate --file $(DEMO_DIR)/callgraph.dot
	@echo "Generated: $(DEMO_DIR)/callgraph.dot"
	@dot -Tsvg $(DEMO_DIR)/callgraph.dot -o $(DEMO_DIR)/callgraph.svg || echo "Graphviz not found: skipped SVG render"
	@echo "If Graphviz is installed, SVG is at: $(DEMO_DIR)/callgraph.svg"

demo-modulegraph: install-test
	$(call MKDIR_P,$(DEMO_DIR))
	$(VENV_PYTHON) -m pyan.main --module-level tests/test_code_modvis/**/*.py --dot -c -e --file $(DEMO_DIR)/modulegraph.dot
	@echo "Generated: $(DEMO_DIR)/modulegraph.dot"
	@dot -Tsvg $(DEMO_DIR)/modulegraph.dot -o $(DEMO_DIR)/modulegraph.svg || echo "Graphviz not found: skipped SVG render"
	@echo "If Graphviz is installed, SVG is at: $(DEMO_DIR)/modulegraph.svg"

demo-text: install-test
	$(call MKDIR_P,$(DEMO_DIR))
	$(VENV_PYTHON) -m pyan.main tests/orbital/*.py --uses --no-defines --text > $(DEMO_DIR)/callgraph.txt
	@echo "Generated: $(DEMO_DIR)/callgraph.txt"

demo-paths: install-test
	$(call MKDIR_P,$(DEMO_DIR))
	$(VENV_PYTHON) -m pyan.main tests/orbital/*.py --paths-from orbital.mission.plan_mission --paths-to orbital.mission.delta_v > $(DEMO_DIR)/paths.txt || echo "Path query returned no results; inspect function names"
	@echo "Generated (or attempted): $(DEMO_DIR)/paths.txt"

clean:
	-$(call RM_RF,.pytest_cache)
	-$(call RM_RF,.ruff_cache)
	-$(call RM_RF,.mypy_cache)
	-$(call RM_RF,build)
	-$(call RM_RF,dist)
	-$(call RM_RF,*.egg-info)
	-$(call RM_RF,$(DEMO_DIR))
	-$(call RM_RF,htmlcov)
	-$(VENV_PYTHON) -m coverage erase 2> NUL || true
	@echo "Cleaned caches and generated files"

clean-demo:
	-$(call RM_RF,$(DEMO_DIR))
	@echo "Cleaned demo outputs"

clean-venv:
	-$(call RM_RF,$(VENV_DIR))
	@echo "Removed virtual environment $(VENV_DIR)"
