FROM python:3.9-slim
FROM rasa/rasa:3.6.2

# Configura variables de entorno para reducir el uso de memoria
ENV PYTHONUNBUFFERED=1
ENV RASA_TELEMETRY_ENABLED=false
ENV TF_CPP_MIN_LOG_LEVEL=2
ENV TENSORFLOW_IO_ENABLE_OUTLIER_DETECTION=false
ENV PORT=5005

# Configura el directorio de trabajo
COPY . /app
WORKDIR /app

# Copia solo los archivos necesarios primero
COPY requirements.txt ./

# Instala las dependencias con pip
RUN pip install --no-cache-dir -r requirements.txt \
    && pip cache purge \
    && rm -rf /root/.cache /tmp/* /var/tmp/*

# Copiar solo los archivos necesarios
COPY config.yml domain.yml credentials.yml endpoints.yml ./
COPY data/ ./data/
COPY models/ ./models/ 

# Copia el resto de los archivos del proyecto
COPY . .

# Limpia archivos innecesarios después de la instalación
RUN find . -type d -name "__pycache__" -exec rm -r {} + && \
    rm -rf /root/.cache

# Healthcheck para Render
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/health || exit 1

# Expone el puerto
EXPOSE 5005

# Comando optimizado para Render
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "5005", "--endpoints", "endpoints.yml", "--credentials", "credentials.yml", "--log-file", "rasa.log", "--debug"]

#CMD rasa run --enable-api --cors "*" --port "5005" --endpoints "endpoints.yml" --credentials "credentials.yml" --log-file "rasa.log" --debug

#CMD ["sh", "-c", "rasa", "run", "--enable-api", "--cors", "*", "--model", "/app/models", "--port", "5005"]

#CMD ["sh", "-c", "rasa run --enable-api --cors '*' --host 0.0.0.0 --port $PORT -vv & rasa run actions --port 5055 -vv"]
