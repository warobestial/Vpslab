FROM python:3.9-slim

# Instalar dependencias básicas
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Instalar OCI CLI (La herramienta de Oracle)
RUN bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

# Añadir el binario al path
ENV PATH="/root/bin:$PATH"

# Copiar el script y dar permisos
COPY script.sh /app/script.sh
RUN chmod +x /app/script.sh

WORKDIR /app

# Ejecutar
CMD ["./script.sh"]
