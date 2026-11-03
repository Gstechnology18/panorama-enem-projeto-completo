# Panorama ENEM

## Baixar e compartilhar

Este repositório reúne o código da aplicação, a documentação, os testes, os dados sintéticos de demonstração e os materiais de apresentação.

```bash
git clone https://github.com/Gstechnology18/panorama-enem-projeto-completo.git
cd panorama-enem-projeto-completo
```

Também é possível baixar tudo pelo botão **Code → Download ZIP**. Após extrair, abra um terminal na pasta que contém este README. Para executar localmente, tenha Python 3.12 e Node.js 22 com npm instalados, ou use Docker Compose conforme as instruções abaixo.

### Materiais de apresentação

- [Vídeo de demonstração](videos-apresentacao/panorama-enem-demonstracao.mp4)
- [Roteiro da apresentação](videos-apresentacao/roteiro-video.txt)
- [Capturas de tela em 4K](prints-apresentacao/)
- [Como rodar no Windows](COMO_RODAR_WINDOWS.txt)

![Tela inicial do Panorama ENEM](prints-apresentacao/panorama-enem-inicio-4k.png)

Os microdados oficiais brutos e processados, as dependências instaladas e os ambientes virtuais não fazem parte do repositório. O modo de demonstração funciona com a base sintética incluída; para analisar os dados oficiais, siga a seção de processamento dos microdados.

---

Aplicação web analítica do Projeto Aplicado III — Ciência de Dados e Inteligência Artificial (SENAI/SC).

O sistema transforma os microdados oficiais do ENEM em consultas estatísticas acessíveis e personalizadas, cobrindo as edições de **2018 a 2025**. O escopo implementa os quatro módulos previstos no plano: percentil por área, recorte socioeconômico, comparação por UF/tipo de escola e posicionamento na redação.

## O que já está implementado

- ETL reprodutível para ZIP/CSV oficial do INEP, em chunks;
- contrato de dados comum 2018–2025;
- saída Parquet + ZSTD particionada por edição;
- motor analítico DuckDB para consulta direta dos Parquets;
- percentil empírico exato e z-score dentro da mesma edição;
- FastAPI com validação, CORS, OpenAPI e tratamento de erro;
- interface React/Vite responsiva e acessível;
- quatro módulos analíticos completos;
- modo demonstração que funciona sem baixar dezenas de GB;
- Docker Compose;
- testes automatizados e CI com meta mínima de 60% de cobertura;
- documentação de arquitetura, metodologia e implantação;
- base Terraform para armazenamento seguro em AWS S3.

## 1. Rodar imediatamente (modo demonstração)

### Windows PowerShell

```powershell
.\scripts\start-dev.ps1
```

Ou manualmente:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
uvicorn app.main:app --app-dir backend --reload --port 8000
```

Em outro terminal:

```powershell
cd frontend
npm install
npm run dev
```

Acesse:

- Aplicação: `http://localhost:5173`
- Swagger da API: `http://localhost:8000/docs`

## 2. Rodar com Docker

```bash
docker compose up --build
```

Acesse `http://localhost:8080`.

## 3. Usar a camada gold do ETL (`enem_projeto_aplicado`)

A fonte oficial principal é a camada gold gerada pelo ETL do grupo
([enem_projeto_aplicado](https://github.com/GabrielSartoriMosquer/enem_projeto_aplicado)):
um único `data/gold/enem_notas.parquet` com as 8 edições (2018–2025). Com os dois
repositórios lado a lado:

```text
Projeto Aplicado III/
├── enem_projeto_aplicado/          # ETL (gera data/gold/enem_notas.parquet)
└── panorama-enem-projeto-completo/ # esta aplicação
```

```bash
cp .env.example .env    # já aponta PANORAMA_GOLD_PATH para ../enem_projeto_aplicado/data/gold/
make gold               # (re)gera a gold no repositório do ETL
make api                # a API passa a responder com "data_source": "official"
```

No Docker Compose a pasta da gold é montada em `/app/backend/data/gold` (outro caminho:
`ENEM_GOLD_DIR=/caminho/da/gold docker compose up --build`).

Como a gold é lida (`GoldEngine` em `backend/app/services/data_engine.py`):

- `TIPO_ESCOLA` vira `TP_ESCOLA` (2 = pública, 3 = privada). De 2018 a 2023, vazio significa
  "não respondeu" (1). Os 13.877 registros de escola no exterior de 2018 ficam fora do recorte;
- `ESCOLARIDADE_PAI`, `ESCOLARIDADE_MAE` e `RENDA_FAMILIAR` (já harmonizadas pelo ETL) viram
  Q001, Q002 e Q006;
- quem tirou 0 em alguma prova objetiva (`IN_NOTA_ZERO`) fica fora de todas as estatísticas,
  como recomenda o ETL;
- em 2024 e 2025 o INEP publicou perfil e notas em arquivos sem ligação. Percentil, redação e
  ranking por UF funcionam normalmente; recorte socioeconômico e por tipo de escola ficam vazios
  e a interface avisa.

Ordem de escolha da fonte em `PANORAMA_DATA_MODE=auto`: gold do ETL → Parquets particionados
(seção 4) → base sintética de demonstração. Gold sem a coluna `IN_NOTA_ZERO` (gerada antes de
03/11/2026) é recusada; rode `make gold` de novo.

## 4. Processar os microdados oficiais (ETL embutido, alternativo)

Uma edição:

```bash
python -m app.etl.cli all --years 2025
```

Todas as edições do escopo:

```bash
python -m app.etl.cli all --years 2018-2025
```

O pipeline gera:

```text
backend/data/parquet/
├── ano=2018/enem.parquet
├── ano=2019/enem.parquet
├── ...
└── ano=2025/enem.parquet
```

A configuração padrão `PANORAMA_DATA_MODE=auto` detecta os Parquets e passa a usar automaticamente os microdados processados. Sem Parquet, usa o dataset sintético de demonstração.

## 5. Testes

```bash
pytest --cov=backend/app --cov-report=term-missing
```

`backend/tests/test_gold_engine.py` cria uma gold pequena com o mesmo esquema da real.
`backend/tests/test_gold_real.py` roda os módulos sobre a gold real em todas as edições quando
ela existe (`ENEM_GOLD_PATH` ou `../enem_projeto_aplicado/data/gold/enem_notas.parquet`); sem
ela, esses testes são pulados (caso do CI).

## Estrutura

```text
backend/
  app/
    api/        # rotas REST
    core/       # config, modelos e constantes
    etl/        # download, padronização e Parquet
    services/   # motor estatístico e engines de dados
  tests/
  data/demo/
frontend/
  src/
docs/
infra/terraform/
scripts/
docker-compose.yml
```

## Limitações metodológicas

- Não há comparação de nota bruta entre edições diferentes.
- Não há previsão de aprovação ou nota futura.
- As análises são estatístico-descritivas; associação não implica causalidade.
- A aplicação é anônima e não persiste histórico individual.
- O dataset `backend/data/demo/enem_demo.csv` é sintético e serve apenas para validar funcionamento. Para resultados acadêmicos, rode o ETL sobre os microdados oficiais do INEP.
