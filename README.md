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

## 🚀 Como Submeter sua Solução

Para participar do desafio **Ingestão no Limite**, siga os passos abaixo:

### Passo 1: Desenvolva sua solução
1. Crie um **novo repositório público** na sua conta do GitHub para o seu código.
2. Desenvolva sua solução na linguagem que desejar (Python, Rust, Go, C++, etc.).
3. **Requisito Obrigatório:** Na **raiz** do seu repositório deve existir um `Dockerfile` que prepare o ambiente e execute a ingestão automaticamente ao iniciar o container.
4. Garanta que seu container grave a saída Delta Lake no MinIO configurado (`s3://marketing-leads/silver_empresas`).

### Passo 2: Envie sua submissão para a Rinha
1. Faça um **Fork** deste repositório (`mpraes/ingestao_no_limite`).
2. No seu fork, crie um arquivo dentro da pasta `submissoes/` com o seu nome de usuário do GitHub:
   `submissoes/seu_usuario.json`
3. Preencha o JSON exatamente com a estrutura abaixo:

```json
{
  "participante": "seu_usuario",
  "repositorio": "[https://github.com/seu_usuario/seu-repo-da-solucao](https://github.com/seu_usuario/seu-repo-da-solucao)"
}
