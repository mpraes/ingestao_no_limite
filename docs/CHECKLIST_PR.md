# 📑 Checklist para Envio de Pull Request

Antes de abrir o seu Pull Request para avaliação, verifique se cumpriu todos os pontos abaixo:

- [ ] O código lê os arquivos compactados `.zip` sem depender de extração manual prévia no SO.
- [ ] O `Dockerfile` está na raiz do repositório e instala todas as dependências necessárias.
- [ ] As variáveis do MinIO/S3 usam o endpoint `localhost:9000`.
- [ ] O script grava os dados finais em `s3://marketing-leads/silver_empresas`.
- [ ] O código trata conversão de encoding `ISO-8859-1` para `UTF-8`.
- [ ] A conversão de vírgula para ponto no `capital_social` foi aplicada.
- [ ] O filtro de `capital_social > 1000.00` e remoção de CPF na `razao_social` estão ativos.
- [ ] O container roda e finaliza dentro do limite de **2 GB de RAM**.
