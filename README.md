# ⚡ Ingestão no Limite: Um desafio para que engenheiros de dados possam realmente engenhocar seus pipelines

Seja bem-vindo ao **Ingestão no Limite**, o desafio de Engenharia de Dados focado em **eficiência extrema, código performático e FinOps**.

O objetivo é simples: construir um pipeline em Python (ou outra linguagem) capaz de processar, tratar e enriquecer a base de dados públicos de CNPJs do Brasil (dados.gov.br) rodando sob restrições severas de hardware: **máximo de 2 GB de RAM e 2 vCPUs**.

---

## 🏆 Como Funciona?

1. **Faça o Fork** deste repositório.
2. **Desenvolva seu código** de ingestão e tratamento ajustando o `Dockerfile` e o script principal.
3. **Abra um Pull Request** contra a branch `main`.
4. O nosso servidor local (**Hardware Celeron**) vai capturar seu PR automaticamente, rodar o pipeline no Docker isolado e cronometrar sua performance.
5. Se passar em todas as regras de **Data Quality**, seu tempo e consumo de storage vão direto para o **Ranking Oficial**!

---

## 📚 Documentação Completa (`/docs`)

Para não travar no contrato de dados ou ser desclassificado por estouro de memória, leia os guias abaixo antes de codar:

* 📄 [**Regras de Negócio e Contrato de Dados**](./docs/REGRAS_E_CONTRATO.md) - Schemas, filtros B2B, tipos de dados e encoding.
* 💻 [**Stack do Servidor e Limites de Hardware**](./docs/STACK_E_LIMITES.md) - Especificações da máquina de teste (RAM/CPU/MinIO).
* 🚀 [**Tutorial Inicial de Execução Local**](./docs/TUTORIAL_INICIAL.md) - Como rodar e testar no seu próprio computador antes de abrir o PR.
* 📑 [**Checklist Obrigatório para Pull Request**](./docs/CHECKLIST_PR.md) - Requisitos para garantir que seu PR seja aceito sem erros.

---

## 🏎️ Critérios de Ranking

O ranking é ordenado por **Menor Tempo de Execução (Wall Time)** e desempata por **Menor Espaço Consumido em Storage (MB)**. 

> *"Engenharia de dados de verdade não é sobre contratar o maior cluster da nuvem, é sobre escrever código otimizado."*# ingestao_no_limite
