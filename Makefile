.PHONY: install test api web demo docker etl-2025 etl-all gold

install:
	python -m pip install -e '.[dev]'
	cd frontend && npm install

test:
	pytest --cov=backend/app --cov-report=term-missing

api:
	uvicorn app.main:app --app-dir backend --reload --port 8000

web:
	cd frontend && npm run dev

docker:
	docker compose up --build

etl-2025:
	python -m app.etl.cli all --years 2025

etl-all:
	python -m app.etl.cli all --years 2018-2025

# Gera a camada gold no repositório do ETL (ao lado deste) e a API passa a usá-la
gold:
	cd ../enem_projeto_aplicado && uv run python -m enem_pja3.load.load
