# 🎯 ROADMAP DE TRANSIÇÃO DE CARREIRA — Roberto Nascimento
> Criado: 2026-03-03 | Atualizado: 2026-03-04
> Objetivo: Transição de Analista de Campo (Veolia) → Engenheiro de Dados / IIoT / Software
> Prazo-Alvo: Q3 2026 (6 meses)
> Trilhas: Data Engineer | Backend Python | ⭐ IIoT/Ignition (NOVA)

---

## 📊 DIAGNÓSTICO ATUAL (Strengths & Gaps)

### ✅ O Que Você JÁ TEM (Seus Diferenciais)

| Ativo | Nível | Evidência |
|-------|:-----:|-----------|
| **Python** | Intermediário-Avançado | LabStock SaaS, 5 projetos GitHub |
| **SQL Avançado** | Sólido | BigQuery, modelagem dimensional |
| **Django** | Intermediário | LabStock (Django 5 + HTMX + Alpine.js) |
| **Docker** | Intermediário | Dockerfile, docker-compose em produção |
| **GCP (Cloud Run, BigQuery)** | Intermediário | Deploy real em Cloud Run |
| **dbt** | Intermediário | ELT com testes na origem |
| **Git/GitHub** | Sólido | 5 projetos públicos, CI/CD configurado |
| **Formação Acadêmica** | Forte | BSc Ciência da Computação + MBA Eng. Software |
| **Domínio Industrial** | Excepcional | 6+ anos SCADA/SDCD em processos críticos (água/química) |
| **SCADA/Supervisórios** | Intermediário | Operação real de SDCD/SCADA na Veolia e Unifor |
| **Ignition (Inscrito)** | Iniciante | Inductive University — treinamento em andamento |
| **Antigravity System** | Avançado | 950+ skills, 27 livros RAG, 7 Leis Living Spec |

### ⚠️ Gaps Críticos Para o Mercado (O Que Falta)

| Gap | Por Que Importa | Prioridade |
|-----|-----------------|:----------:|
| **Testes Automatizados (pytest)** | 90% das vagas pedem TDD/testes | 🔴 URGENTE |
| **API REST Profissional (FastAPI)** | Vagas Data Eng pedem microserviços | 🔴 URGENTE |
| **Spark na prática (PySpark)** | Diferencial em vagas Mid/Senior | 🟡 ALTA |
| **Inglês Técnico (Escrita)** | README, PR descriptions, docs | 🟡 ALTA |
| **System Design Interview** | Exigido em entrevistas Mid+ | 🟡 ALTA |
| **Contribuição Open Source** | Diferencial brutal no LinkedIn | 🟢 MÉDIA |
| **OPC UA / MQTT** | Protocolo padrão de comunicação industrial moderna | 🟡 ALTA |
| **Ignition Certificação (Core + Gold)** | Passe direto para vagas seniores em integração TI/TA | 🔴 URGENTE |

---

## 🗺️ PLANO DE 6 MESES (Março → Agosto 2026)

### MÊS 1-2: FUNDAÇÃO (Março-Abril)
- [ ] **Projeto 1:** API REST com FastAPI + PostgreSQL + Testes (pytest)
  - CRUD completo com autenticação JWT
  - 80%+ code coverage
  - Dockerizado e deployado no Cloud Run
  - README em inglês impecável
- [ ] **Ignition:** Completar módulos Core da Inductive University
  - Instalar Ignition local (trial mode)
  - Criar primeiro projeto com tags simuladas (OPC UA)
  - Scripting com Python no Ignition
- [ ] **Treino Diário:** 1 desafio SQL no LeetCode/HackerRank (30 min/dia)
- [ ] **Treino Semanal:** 1 questão de System Design (livro Alex Xu — já no RAG)
- [ ] **Portfolio:** Deploy do site pessoal (Django) no Cloud Run ← PENDENTE
- [ ] **LinkedIn:** Publicar 1 post técnico/semana (caso real do LabStock ou pipeline)

### MÊS 3-4: PROFUNDIDADE (Maio-Junho)
- [ ] **Projeto 2:** Pipeline de Dados E2E com Airflow + dbt + BigQuery
  - Ingestão de API pública → Bronze → Silver → Gold (Medallion)
  - Orquestrado com Airflow 3 (TaskFlow API)
  - Transformações com dbt (testes + docs)
  - Dashboard final em Streamlit ou Metabase
- [ ] **Projeto IIoT-1:** Pipeline de Dados Industriais (Sensor → Data Lake)
  - Simular planta de tratamento de água no Ignition
  - Tags OPC UA: pH, pressão, nível, vazão
  - Transaction Groups → PostgreSQL (Data Historian)
  - Python scripts no Ignition → JSON → API REST → Databricks/BigQuery
- [ ] **Spark:** Processar dataset de 1GB+ com PySpark (local + Databricks)
- [ ] **Certificação:** Ignition Core Certified + GCP Data Engineer (opcional)
- [ ] **Open Source:** 1ª contribuição (fix de bug ou docs em projeto popular)

### MÊS 5-6: POSICIONAMENTO (Julho-Agosto)
- [ ] **Projeto 3:** Microsserviço com Event-Driven Architecture
  - FastAPI + Redis (Pub/Sub ou Celery) + PostgreSQL
  - Monitoramento com logs estruturados
  - CI/CD completo (GitHub Actions → Cloud Run)
- [ ] **Projeto IIoT-2:** Integração SCADA + Sistema de Gestão de Estoque
  - Interface Perspective (IHM web) no Ignition
  - Integração com sistema de inventário (LabStock-style)
  - Dosagem química → dedução automática de estoque
  - Auditoria completa: quem acionou, quando, impacto
- [ ] **Entrevistas Mock:** 10 sessões de System Design + Behavioral
- [ ] **Aplicações:** 5-10 candidaturas/semana em vagas-alvo
- [ ] **Networking:** Participar de 2 meetups/comunidades (Data Engineering BR, Python BR, ISA)

---

## 🎯 VAGAS-ALVO (O Que Mirar)

### ⭐ Trilha 3: IIoT / Engenheiro de Integração TI-TA (MAIOR SALÁRIO)
- **Pleno:** Ignition, OPC UA, Python, SQL, SCADA/HMI
- **Sênior:** + PI System (AVEVA), Cibersegurança Industrial (IEC 62443), Cloud
- **Empresas-Alvo:** Veolia (interno), SABESP, AEGEA, Emerson, ABB, Siemens, Schneider, ATOS
- **Faixa Salarial:** R$ 12k-25k+ (Convergência TI/TA é escasso no mercado)
- **Seu Diferencial ÚNICO:** BSc Computação + MBA Eng. Software + 6 anos de chão de fábrica

### Trilha 1: Data Engineer
- **Júnior/Pleno:** Python, SQL, ETL, Airflow, BigQuery/Databricks
- **Pleno/Sênior:** + Spark, Kafka, Terraform, System Design
- **Empresas-Alvo:** iFood, Nubank, Mercado Livre, PicPay, Stone, Loft, Creditas

### Trilha 2: Backend Engineer (Python)
- **Júnior/Pleno:** Python, Django/FastAPI, PostgreSQL, Docker, testes
- **Pleno/Sênior:** + Kubernetes, microsserviços, mensageria
- **Empresas-Alvo:** Luizalabs, VTEX, Pagar.me, Wildlife, Gympass

---

## 📁 ESTRUTURA DO WORKSPACE

```
/media/Arquivos/Engenharia TI 2026/
├── 01_Fundamentos/         ← Exercícios SQL, Python, System Design
├── 02_Projetos_Portfolio/   ← Projetos 1, 2 e 3 (código completo)
├── 03_Entrevistas/          ← Mock interviews, perguntas, gabaritos
├── 04_Networking/           ← Posts LinkedIn, conteúdo, contatos
├── 05_Certificacoes/        ← Material de estudo GCP, Databricks
├── 06_Ignition_IIoT/        ← Projetos Ignition, OPC UA, dados industriais
└── ROADMAP.md               ← Este arquivo (atualizar semanalmente)
```

---

## 📈 MÉTRICAS DE PROGRESSO (Atualizar Semanalmente)

| Métrica | Meta Semanal | Acumulado |
|---------|:---:|:---:|
| Desafios SQL resolvidos | 5 | 0 |
| Posts LinkedIn publicados | 1 | 0 |
| System Design estudados | 1 | 0 |
| Commits nos projetos | 15+ | 0 |
| Módulos Ignition concluídos | 2-3 | 0 |
| Candidaturas enviadas | — | 0 |
| Entrevistas realizadas | — | 0 |

---

> *"A IA é seu espelho, ela revela mais rápido quem você é."* — Akita
> *"Engineered systems beat ad-hoc hustle."* — Antigravity Protocol
