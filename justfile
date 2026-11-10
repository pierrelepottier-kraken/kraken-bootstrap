# CI contract: every job repository provides install, lint, test, and ci.
python := env("PYTHON", "python3")

# List the available commands.
default:
    @just --list

# Create the virtual environment and install development dependencies.
install:
    "{{python}}" -m venv .venv
    .venv/bin/python -m pip install -r requirements-dev.txt

# Check Python code with Ruff. Return a nonzero exit code on failure.
lint:
    .venv/bin/python -m ruff check .

# Run tests and save reports/junit.xml, including test failures.
test:
    .venv/bin/python -m pytest -q --junitxml=reports/junit.xml

# Run lint, then tests. Run the install recipe first.
ci: lint test
