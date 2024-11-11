PYTHON_FILES = $(shell find $(TOP_DIR) -name '*.py' -not -path  './.direnv/*' -not -path './tests/*' -not -path './.vscode/*')

pystyle:
	yapf -i $(PYTHON_FILES)

pylint:
	pylint $(PYTHON_FILES)

pytest:
	pytest -vv

pycoverage:
	coverage run --source=duino_bus -m pytest
	coverage report -m

requirements:
	pip install --upgrade pip
	pip install -r requirements.txt
