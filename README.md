# Ocorrências Aeronáuticas no Brasil: banco de dados em PostgreSQL

Trabalho final da disciplina de Banco de Dados (UFU). O projeto parte dos dados abertos do CENIPA sobre ocorrências aeronáuticas da aviação civil brasileira, normaliza a tabela original, implementa o banco em PostgreSQL e responde a perguntas de análise com consultas SQL, um gatilho e um procedimento armazenado.

## Sobre os dados

- **Fonte:** [Ocorrências aeronáuticas da aviação civil brasileira](https://dados.gov.br/dados/conjuntos-dados/ocorrencias-aeronauticas-da-aviacao-civil-brasileira) (Portal de Dados Abertos, dados do CENIPA). Acesso em 16/07/2026.
- **Tamanho:** quase 16.000 linhas na base original.
- **Problema:** muitas células nulas, colunas repetidas e redundância de dados, o que dificultava as buscas.

## Modelo relacional

![Modelo relacional](docs/modelo_relacional.png)

A tabela original foi normalizada em 12 tabelas:

| Tabela | O que guarda |
|---|---|
| `OCORRENCIA` | Dados do evento: classificação, local, data/hora, relatório, totais |
| `INVESTIGACAO` | Status da investigação e se a aeronave foi liberada |
| `AERONAVE` | Características da aeronave (matrícula, fabricante, modelo, motor, PMD, etc.) |
| `AERONAVE_QTD_MOTOR` | Descrição da quantidade de motores (monomotor, bimotor...) |
| `AERONAVE_OCORRENCIA` | Participação da aeronave na ocorrência (relação N:N): voo, fase, dano, fatalidades |
| `TIPO_OCORRENCIA` | Tipos de ocorrência (taxonomia ICAO) com descrição |
| `OCORRENCIA_TIPO` | Relaciona ocorrências e tipos |
| `FATOR` | Fatores contribuintes (nome, aspecto, condicionante, área) |
| `FATOR_OCORRENCIA` | Relaciona fatores e ocorrências |
| `RECOMENDACAO_TIPO` | Número e conteúdo das recomendações de segurança |
| `DESTINATARIO` | Órgãos e empresas que recebem as recomendações |
| `RECOMENDACAO` | Recomendação emitida para um destinatário em uma ocorrência, com datas e status |

**Principais decisões de normalização:**
- As colunas `codigo_ocorrencia1` a `codigo_ocorrencia4` (uma por tabela original) viraram uma única chave `codigo_ocorrencia`.
- `ocorrencia_pais` foi removida: todos os registros são do Brasil.
- Status de investigação e liberação da aeronave foram para a tabela `INVESTIGACAO`.
- Características da aeronave foram separadas da participação dela em cada ocorrência, já que uma aeronave pode estar em várias ocorrências e uma ocorrência pode ter várias aeronaves.
- A descrição da quantidade de motores depende só da quantidade, então foi para uma tabela própria (2FN).

## Estrutura do repositório

```
.
├── README.md
├── sql/
│   ├── 01_schema.sql              # criação das 12 tabelas
│   ├── 02_gatilho_procedimento.sql # gatilho, função e procedimento
│   └── 03_consultas.sql           # as 8 consultas analíticas
├── data/                          # CSVs tratados, um por tabela
├── docs/
│   ├── modelo_relacional.png      # diagrama do modelo
│   └── relatorio.pdf              # relatório completo do trabalho
└── .gitignore
```

## Como executar

**Requisitos:** PostgreSQL ([versão que você usou]) e `psql` ou pgAdmin.

1. Crie o banco e as tabelas:
   ```bash
   createdb -U postgres aeronaves
   psql -U postgres -d aeronaves -f sql/01_schema.sql
   ```

2. Carregue os CSVs da pasta `data/` **nesta ordem**, por causa das chaves estrangeiras:
   1. `INVESTIGACAO`, `AERONAVE_QTD_MOTOR`, `TIPO_OCORRENCIA`, `FATOR`, `DESTINATARIO`, `RECOMENDACAO_TIPO`
   2. `AERONAVE`
   3. `OCORRENCIA`
   4. `AERONAVE_OCORRENCIA`, `OCORRENCIA_TIPO`, `FATOR_OCORRENCIA`, `RECOMENDACAO`

   Pelo pgAdmin: botão direito na tabela, *Import/Export Data*. Pelo `psql`:
   ```sql
   \copy investigacao FROM 'data/investigacao.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
   ```
   Se a ordem das colunas do CSV for diferente da ordem da tabela, liste as colunas: `\copy tabela (col1, col2, ...) FROM ...`.

3. Crie o gatilho e o procedimento:
   ```bash
   psql -U postgres -d aeronaves -f sql/02_gatilho_procedimento.sql
   ```

4. Rode as consultas de `sql/03_consultas.sql` (uma por vez, no pgAdmin ou no `psql`).

## Consultas

| # | Pergunta |
|---|---|
| 4.1.1 | Quais são as 10 cidades com maior número de ocorrências? |
| 4.1.2 | Quais fatores contribuintes estão mais associados a ocorrências com fatalidades? |
| 4.1.3 | Quais modelos de aeronave (e seus fabricantes) estão mais envolvidos em ocorrências? |
| 4.1.4 | Entre as ocorrências do modelo ATR-72-212A, quais tipos foram mais frequentes? |
| 4.1.5 | Quais fabricantes têm o maior número de ocorrências? |
| 4.1.6 | Quais fabricantes têm total de fatalidades acima da média entre os fabricantes? |
| 4.1.7 | Quais aeronaves têm mais ocorrências que a média geral por aeronave? |
| 4.1.8 | Para quais destinatários foram emitidas recomendações da ocorrência mais fatal, e quantas cada um recebeu? |

**Alguns resultados:**
- A cidade com mais ocorrências é o Rio de Janeiro (1.088), seguida de Guarulhos (857) e São Paulo (786).
- O modelo mais envolvido é o ATR-72-212A (474 ocorrências). O tipo mais frequente nele é falha ou mau funcionamento de sistema/componente (184).
- O fator contribuinte com mais fatalidades associadas é "Julgamento de pilotagem" (756).

## Gatilho e procedimento armazenado

- **Gatilho** `trg_validar_fatalidades`: em `INSERT` ou `UPDATE` na tabela `aeronave_ocorrencia`, bloqueia valores negativos de `aeronave_fatalidades_total`.
- **Função** `relatorio_modelo_aviao(modelo)`: retorna uma linha com fabricante, total de ocorrências, tipo de ocorrência, fase da operação e fator contribuinte mais frequentes para um modelo de aeronave.
- **Procedimento** `relatorio_modelo_aviao_proc(modelo)`: chama a função e exibe o relatório com `RAISE NOTICE`.

```sql
SELECT * FROM relatorio_modelo_aviao('ATR-72-212A');
CALL relatorio_modelo_aviao_proc('ATR-72-212A');
```

## Tratamento dos dados

- Quando a chave primária estava nula (linhas vazias com número de ocorrência existente), foram criadas chaves no mesmo padrão dos dados originais, como `UNKNOWN001` e `UNKNOWN002` em `aeronave_matricula`, para representar aeronaves desconhecidas ou com poucos dados.
- Em `RECOMENDACAO`, três registros repetiam a chave primária (`codigo_ocorrencia`, `recomendacao_numero`, `destinatario_sigla`) e diferiam só em `recomendacao_dia_encaminhamento`. Foi mantido o de data mais recente, pois eram a mesma recomendação reenviada em um curto intervalo.
- Os arquivos foram convertidos de `.xlsx` para `.csv` (UTF-8) antes da importação.

## Limitações conhecidas

- Nomes de fabricantes não foram unificados. Variações como `BOEING` e `BOEING COMPANY`, ou `AIRBUS`, `AIRBUS S.A.S.` e `AIRBUS INDUSTRIE`, aparecem separadas nos rankings de fabricantes (4.1.5 e 4.1.6).
- Na consulta 4.1.2, uma ocorrência com vários fatores contribui com suas fatalidades para cada um deles. Por isso, os totais por fator não somam o total de fatalidades.
- Os valores `DESCONHECIDO` e as chaves `UNKNOWN***` representam dados ausentes na origem.

## Tecnologias

PostgreSQL, pgAdmin, SQL e PL/pgSQL. Gráficos feitos no Excel.

## Uso de IA

Modelos de linguagem foram usados para reorganizar colunas das tabelas após a normalização e para tirar dúvidas sobre `RETURNS TABLE` e `RETURN NEXT` no procedimento armazenado. Detalhes na seção 5 do relatório (`docs/relatorio.pdf`).

## Autores

- [Diogo Pontes](github.com/diogoPontes248)
- [Felipe Cardoso]
- [Guilherme Cotrim](github.com/GuisoBiso67)
- [Sérgio Zordan]
