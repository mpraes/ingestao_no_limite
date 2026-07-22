# Ingestão no Limite: Um desafio para os engenheiros de dados "engenhocar" seus pipelines

<img width="986" height="921" alt="image" src="https://github.com/user-attachments/assets/51a885fc-6902-4a6a-ac44-fedf5825690a" />

Seja bem-vindo ao **Ingestão no Limite**, o desafio de Engenharia de Dados focado em **eficiência extrema, código performático e FinOps**.

*Contexto Narrativo*:

Uma agência de marketing B2B precisa de uma base de dados grande e robusta para criar campanhas automatizadas e conquistar o maior número possível de prospectos. No entanto, a agência não está disponível a investir em máquinas virtuais, clusters Kubernetes ou instâncias no Databricks, pois acredita que não são necessários custos elevados para atingir seus objetivos.

Eles baixaram arquivos de empresas no formato CSV pelo site dados.gov.br. Contudo, não conseguem sequer abrir esses arquivos, pois estão compactados em `.zip`, possuem um formato interno incomum e, além disso, são grandes demais para manipular no Excel.

Diante disso, a agência contratou você para criar um processo de ingestão e tratamento simples desses dados, de forma a permitir melhores consultas utilizando ferramentas de BI, como Tableau, Metabase ou Power BI.

O detalhe importante: o único equipamento disponível é um notebook antigo, que eles acreditam ser suficiente para o serviço.

## 🎯 Objetivo da Competição

Criar o pipeline de ingestão e tratamento dos dados empresariais **mais eficiente possível**, operando sob rigorosas restrições de hardware (máximo de **1 GB de RAM**, **2 CPUs** e **60 min** para processar ~68,6M linhas).

Ao final, seu trabalho deve gerar uma **tabela padronizada e pronta para BI** no PostgreSQL. Você decide a arquitetura: pode usar **object storage compatível com S3** como apoio (staging, Parquet, Delta Lake, Iceberg) ou ir direto ao Postgres — o que importa é **passar nos gates** e **vencer no ranking**.

Ao longo do processo, você deverá manipular múltiplos arquivos `.zip`, converter encodings e tipos de dados, aplicar regras rigorosas de qualidade de dados e **carregar todas as linhas** da origem (sem filtro), derivando **colunas de negócio** que segmentam a base para o BI — por exemplo, faixa de `capital_social`, flag `is_mei`, grupo de natureza jurídica e presença de ente federativo. É uma abordagem **ELT**: carregue o dado bruto e classifique-o em colunas, em vez de descartar registros.

Todos os critérios serão verificados automaticamente. Apenas soluções que passem em **todos os gates** serão consideradas para o ranking.

Esse desafio testa sua habilidade em otimizar, manipular grandes volumes de dados e desenvolver soluções robustas, criativas e enxutas — uma simulação de cenário real, onde a infraestrutura é fornecida e **você escolhe a melhor abordagem**.

---



## 🏗️ Infraestrutura Fornecida

A competição disponibiliza **duas ferramentas**. Você escolhe como usá-las:


| Serviço                                  | Papel                                               | Obrigatório?                               |
| ---------------------------------------- | --------------------------------------------------- | ------------------------------------------ |
| **PostgreSQL** (`db_empresas`)           | Destino final da tabela de negócio para BI          | **Sim** — tabela `{participante}_empresas` |
| **S3-compatível** (MinIO no laboratório) | Object storage para staging, intermediários ou lake | **Não** — uso opcional a seu critério      |




### Entrega obrigatória (finish line)

```
db_empresas.public.{participante}_empresas
```

Onde `{participante}` é exatamente o valor do campo `participante` no seu JSON de submissão (ex.: `renan_python` → `renan_python_empresas`).

---



## 🏆 Como Funciona?

1. **Faça o Fork** deste repositório.
2. **Desenvolva seu código** de ingestão em um **repositório público seu** (`Dockerfile` na raiz + `src/`). No fork oficial, envie apenas `submissions/seu_usuario.json`.
3. **Abra um Pull Request** contra a branch `main` com seu arquivo em `submissions/seu_usuario.json` e **faça merge** após revisão.
4. **Após o merge**, o servidor local (**Hardware Celeron**) enfileira a avaliação, executa **preflight**, roda o pipeline no Docker isolado e coleta métricas.
5. Se passar em **todos os gates**, seu **score composto** (tempo + RAM + storage) entra no **Ranking Oficial**.

> A avaliação **não** roda enquanto o PR está aberto — só depois que o JSON entra na `main`. O organizador pode reavaliar manualmente via **Actions → Run workflow** (sem novo PR).

---



## 📚 Documentação Completa (`/docs`)

Para não travar no contrato de dados ou ser desclassificado por estouro de memória, leia os guias abaixo antes de codar:

- 📄 **[Regras de Negócio e Contrato de Dados](./docs/REGRAS_E_CONTRATO.md)** — Schema (13 colunas), carga completa, tipos de dados e encoding.
- 🏛️ **[Arquitetura do Projeto e Workflow](./docs/ARCHITECTURE.md)** — Componentes, fluxos, gates e diagramas.
- 💻 **[Stack do Servidor, Variáveis e Acesso na Avaliação](./docs/STACK_E_LIMITES.md)** — Como a avaliação conecta ao Postgres/S3, env vars, licença do MinIO e limites de hardware.
- 🚦 **[Gates, Ranking e Juiz Automático](./docs/GATES_E_RANKING.md)** — Gates de aprovação, métricas, timeout, fila e SQL de validação.
- 🐍 **[Judge (](./evaluator/judge/README.md)**`/evaluator/judge`**[)](./evaluator/judge/README.md)** — `validar.py` + SQL executado pelo evaluator.
- 📑 **[Checklist Obrigatório para Pull Request](./docs/CHECKLIST_PR.md)** — Requisitos antes de abrir o PR e fazer merge para avaliação.

---



## 🏎️ Critérios de Ranking

Entre soluções **classificadas** (todos os gates aprovados), a ordem é dada por um **score composto** (menor vence) — não é mais só velocidade:

```
score = 0.60·(tempo/3600) + 0.25·(peak_ram/1024) + 0.15·(storage_total/4096)
```

- **60% tempo**, **25% RAM**, **15% storage** — recompensa eficiência holística.
- Ser mais rápido **não basta** se você desperdiça RAM (o recurso escasso: 1 GB) ou escreve uma tabela inchada.
- Desempates (se o score empatar): tempo → storage → RAM → ordem de chegada.

> *"Engenharia de dados de verdade não é sobre contratar o maior cluster da nuvem, é sobre escrever código otimizado."*

Detalhes completos e exemplos em [Gates, Ranking e Juiz Automático](./docs/GATES_E_RANKING.md).

---



## 🚀 Como Submeter sua Solução

> **Dois repositórios, papéis diferentes**
>
>
> | Repositório                     | O que vai lá                                                                  |
> | ------------------------------- | ----------------------------------------------------------------------------- |
> | **Seu repo público de solução** | `Dockerfile`, `src/`, `participante.json`, `requirements.txt` — só o pipeline |
> | **Fork deste repo oficial**     | Apenas `submissions/seu_usuario.json` apontando para o seu repo               |
>
>
> **Não** abra PR com o código da ingestão dentro do repo oficial (`docs/`, `evaluator/`, etc.). O evaluator **clona o URL** do campo `repositorio` do JSON — ele precisa ser o **seu** repositório, enxuto e com o `Dockerfile` na raiz.



### Passo 1: Desenvolva sua solução

1. Crie um **novo repositório público** na sua conta do GitHub (ex.: `seu_usuario/ingestao-empresas`).
2. Use este repo oficial só como **referência** (documentação em `/docs` e starter em `submitter/`). Copie o conteúdo de `submitter/` para a **raiz** do **seu** repo.
3. Estrutura mínima recomendada no **seu** repositório (após copiar de `submitter/`):

```
seu-repo-da-solucao/
├── Dockerfile              # obrigatório — na raiz; dispara a ingestão ao iniciar o container
├── requirements.txt        # dependências do build (se usar Python, etc.)
├── participante.json       # seu identificador + URL deste mesmo repo (copie de participante.json.example)
└── src/
    └── main.py             # entrypoint do pipeline (ou outro layout, ajustando o Dockerfile)
```

1. Renomeie `participante.json.example` → `participante.json` (copiado de `submitter/`) e preencha com seu usuário e a URL do **seu** repo.
2. Desenvolva na linguagem que desejar (Python, Rust, Go, C++, etc.) — o starter usa Python apenas como ponto de partida.
3. Grave a tabela final em `db_empresas.public.{participante}_empresas` conforme o [contrato de dados](./docs/REGRAS_E_CONTRATO.md).
4. Object storage S3 é opcional; se usar, limite-se ao prefixo `s3://marketing-leads/{participante}/`. Projete o código contra a **API S3 genérica** — o MinIO na avaliação é apenas alvo de laboratório (ver [licença e alternativas](./docs/STACK_E_LIMITES.md#-object-storage-s3-compatível-opcional)).

O `participante.json` na raiz do **seu** repo é para organização e deve bater com o JSON que você enviará no fork (mesmos `participante` e `repositorio`). O evaluator **não** lê esse arquivo do seu repo — ele usa apenas o JSON em `submissions/` no fork.

### Passo 2: Envie sua submissão para o repo oficial da competição

1. Faça um **Fork** deste repositório (`mpraes/ingestao_no_limite`).
2. No fork, crie **somente** `submissions/seu_usuario.json` (não mova `Dockerfile` nem `src/` para cá).
3. Use a **mesma** estrutura do `participante.json` do seu repo de solução:

```json
{
  "participante": "seu_usuario",
  "repositorio": "https://github.com/seu_usuario/seu-repo-da-solucao",
  "email": "seu_email@exemplo.com"
}
```

O campo `email` é opcional, mas recomendado: após a avaliação o workflow envia um relatório com status, tempo, storage, pico de RAM e posição no ranking.
1. Abra um Pull Request contra a `main` do repo oficial e **faça merge**. Após o merge, o workflow clona o `repositorio` acima e roda o `Dockerfile` **de lá**.

---



## 📁 Estrutura deste repositório

```
ingestao_no_limite/
├── README.md
├── docs/                    # documentação pública
├── submissions/             # metadados de submissão (único conteúdo do PR no fork) 
├── submitter/               # starter — copie para a raiz do SEU repo de solução
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── participante.json.example
│   └── src/
└── evaluator/               # tooling do servidor (organizadores)
    ├── evaluator.sh
    ├── judge/
    ├── scripts/
    └── logs/
```

---



## ⏱️ Limites Operacionais

Para manter a competição divertida e o servidor saudável:


| Regra                      | Valor                                           |
| -------------------------- | ----------------------------------------------- |
| RAM máxima do container    | **1 GB** (sem swap)                             |
| CPUs máximas               | 2                                               |
| Timeout do pipeline        | **60 min** (hard cap; ~68,6M linhas, 7+6 colunas → ~19k linhas/s) |
| Build da imagem            | **15 minutos** (separado; não conta no ranking) |
| Avaliações simultâneas     | 1 (fila única — nunca em paralelo)              |
| Intervalo entre avaliações | **15 minutos** de cooldown (fairness)           |
| PRs duplicados             | apenas o commit mais recente é avaliado         |


Soluções que excederem o timeout ou forem mortas por OOM recebem status de erro e **não entram no ranking**.

---



## ⚖️ Licença do object storage (MinIO)

Na avaliação e no desenvolvimento local, o desafio pode disponibilizar **MinIO dockerizado** apenas como **alvo S3 local para testes e benchmark** — não como recomendação de produção.

- O servidor MinIO é licenciado sob **[GNU AGPLv3](https://github.com/minio/minio/blob/master/LICENSE)**; os binários recentes também estão sujeitos à **[MinIO Software License](https://docs.min.io/license/)**, que restringe o uso sem contrato enterprise a **uma instância, em ambiente não produtivo, para avaliação interna**.
- Usar MinIO **sem modificações** como componente interno de pipeline/CI **não obriga** que o seu código de ingestão seja AGPLv3 — o copyleft atinge trabalhos derivados do MinIO, não programas independentes que apenas falam S3.
- Para **produção** ou replicação do desafio por outros grupos, cada time deve escolher sua própria solução **S3-compatível** (AWS S3, Ceph RADOS Gateway, SeaweedFS, etc.) e avaliar juridicamente o uso pretendido.

Detalhes, alternativas sugeridas e orientações para organizadores estão em [Stack do Servidor — object storage S3-compatível](./docs/STACK_E_LIMITES.md#-object-storage-s3-compatível-opcional).

## Site Ranking

Acesse esse site para ver o ranking se quiser - https://lnk.ink/5R2NA

É um encurtador de link pois eu fiz o site via free ngrok então pode ter um aviso disso.

