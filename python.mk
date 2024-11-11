PYTHON_FILES = $(shell find $(TOP_DIR) -name '*.py' -not -path  './.direnv/*' -not -path './tests/*' -not -path './.vscode/*')

pystyle:
	$(Q)yapf --version
	$(Q)yapf -i $(PYTHON_FILES)

pylint:
	$(Q)pylint --version
	$(Q)pylint $(PYTHON_FILES)

pytest:
	$(Q)pytest --version
	$(Q)pytest -vv

pycoverage:
	$(Q)coverage --version
	$(Q)coverage run --source=duino_bus -m pytest
	$(Q)coverage report -m

requirements:
	pip install --upgrade pip
	pip install -r requirements.txt
