FROM python:3.11-slim
WORKDIR /app

# Simula uma ingestão de 3 segundos que dá sucesso
CMD ["python", "-c", "import time; print('Iniciando simulacao de ingestao...'); time.sleep(3); print('Ingestao concluida com sucesso!')"]
