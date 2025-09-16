PYTHON_FILES = $(shell find $(TOP_DIR) -name '*.py' -not -path  './.direnv/*' -not -path './tests/*' -not -path './.vscode/*')

.PHONY: pystyle
pystyle:
	$(Q)yapf --version
	$(Q)yapf -i --style='{based_on_style: pep8, column_limit: 100}' $(PYTHON_FILES)

.PHONY: pylint
pylint:
	$(Q)pylint --version
	$(Q)pylint $(PYTHON_FILES)

.PHONY: pytest
pytest:
	$(Q)pytest --version
	$(Q)pytest -vv

.PHONY: pycoverage
pycoverage:
	$(Q)coverage --version
	$(Q)coverage run --source=$(basename ${PWD}) --omit=tests/*,./*.py -m pytest
	$(Q)coverage report -m

.PHONY: requirements
requirements:
	pip install --upgrade pip
	pip install -r requirements.txt

.PHONY: install-python-tools
install-python-tools: requirements

.PHONY: run-python-tools
run-python-tools: pylint

ifneq ($(wildcard tests),)
run-python-tools: pytest pycoverage
endif
