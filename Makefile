PYTHON ?= python3

.PHONY: doctor install test lint run
doctor:
	@./scripts/doctor.sh
install:
	$(PYTHON) -m venv .venv && .venv/bin/pip install -q -r requirements-dev.txt
test:
	.venv/bin/pytest -q
lint:
	.venv/bin/ruff check .
run:
	.venv/bin/python -m app.main
