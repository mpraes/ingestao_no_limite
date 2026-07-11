# 💻 Stack do Servidor e Limitações de Hardware

O seu código rodará em uma máquina real com recursos contados. Otimização de I/O, gerenciamento de memória em streaming e escolha das bibliotecas corretas farão toda a diferença.

---

## ⚙️ Especificações da Execução

* **Container Docker Limits:**
  * Memória RAM Máxima: **2 GB** (`--memory="2g"`)
  * vCPUs Máximas: **2 CPUs** (`--cpus="2"`)
* **Armazenamento Alvo:**
  * Endpoint MinIO S3 Local: `http://localhost:9000`
  * Bucket Target: `s3://marketing-leads/silver_empresas`
  * Credenciais de Acesso: `AWS_ACCESS_KEY_ID=admin` | `AWS_SECRET_ACCESS_KEY=minio_password`
* **Formato de Gravação Esperado:** Parquet / Delta Lake / Iceberg.

---

## ⚠️ Atenção ao Out-Of-Memory (OOM)

Se o seu script tentar carregar todos os arquivos de 4 GB direto na memória RAM de uma só vez, o kernel do Docker vai matar o seu container por **OOM (Exit Code 137)** e você será **desclassificado no teste**.

💡 *Dica:* Utilize bibliotecas com suporte a processamento em batch/streaming (Polars, DuckDB, PyArrow, Rust ou Go).
