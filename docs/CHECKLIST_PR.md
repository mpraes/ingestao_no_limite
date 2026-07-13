# 📑 Checklist para Envio de Pull Request

Antes de abrir o Pull Request e fazer **merge** na `main` (o que dispara a avaliação), verifique todos os pontos abaixo:

## Estrutura e execução

- [ ] O código lê os arquivos `.zip` em `/data/` sem extração manual prévia no SO.
- [ ] O `Dockerfile` está na raiz do repositório e instala todas as dependências.
- [ ] O container inicia e executa o pipeline automaticamente (`CMD`/`ENTRYPOINT`).
- [ ] O container finaliza dentro do limite de **2 GB de RAM** (sem OOM).
- [ ] O pipeline completa em menos de **~3h20m** (dataset oficial ~48M linhas).

## Contrato de dados

- [ ] A tabela final existe em `db_empresas.public.{participante}_empresas`.
- [ ] O nome da tabela usa exatamente o campo `participante` do JSON + sufixo `_empresas`.
- [ ] Encoding convertido de `ISO-8859-1` para `UTF-8`.
- [ ] `capital_social` com vírgula BR convertida para ponto decimal.
- [ ] Filtro `capital_social > 1000.00` aplicado.
- [ ] Registros com CPF no final da `razao_social` removidos.
- [ ] Schema e tipos conforme [REGRAS_E_CONTRATO.md](./REGRAS_E_CONTRATO.md).

## Infraestrutura e variáveis de ambiente

- [ ] O código lê **variáveis de ambiente** (`PG_HOST`, `PG_USER`, `PG_PASSWORD`, `PG_DB`, `PARTICIPANTE`, `PG_TABLE`) — sem hardcode de host/senha.
- [ ] Na avaliação, Postgres é acessado via `PG_HOST=postgres_db` (não `localhost`).
- [ ] Dados lidos de `/data/` (zips montados pelo avaliador).
- [ ] Tabela gravada em `public.{PG_TABLE}` no banco `db_empresas`.

## Object storage S3 (opcional)

- [ ] O código fala **API S3 genérica** via `S3_ENDPOINT` — MinIO na avaliação é só alvo de laboratório.
- [ ] Endpoint lido de `S3_ENDPOINT` (`http://minio:9000` na avaliação).
- [ ] Credenciais lidas de `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`.
- [ ] Arquivos apenas no prefixo `s3://marketing-leads/{PARTICIPANTE}/`.
- [ ] Para produção ou fork do desafio: escolha backend S3-compatível próprio (AWS S3, Ceph, SeaweedFS, etc.) — ver [STACK_E_LIMITES.md](./STACK_E_LIMITES.md#-object-storage-s3-compatível-opcional).

## Submissão

- [ ] Arquivo `submissions/seu_usuario.json` criado no fork.
- [ ] JSON contém `participante` e `repositorio` (URL pública do seu código).
- [ ] Repositório da solução é público e contém o `Dockerfile` na raiz.

## Antes de abrir o PR

- [ ] Testou localmente com os mesmos limites de RAM/CPU quando possível.
- [ ] Revisou os [Gates de validação](./GATES_E_RANKING.md) — todas as queries DQ devem retornar 0.

## Após o merge

- [ ] A avaliação dispara automaticamente quando o JSON entra na `main` (workflow `push`).
- [ ] Acompanhe em **Actions → Avaliador de Submissoes** no repo oficial.
- [ ] Para reavaliar sem novo PR (ex.: após corrigir infra), o organizador usa **Run workflow** com `submissions/seu_usuario.json`.
