#!/bin/bash

# --- CONFIGURACIÓN DE CREDENCIALES ---
mkdir -p /root/.oci
# (El contenido de la clave privada viene de la variable de entorno de Easypanel)
echo "$OCI_PRIVATE_KEY" > /root/.oci/oci_api_key.pem
chmod 600 /root/.oci/oci_api_key.pem

cat <<EOF > /root/.oci/config
[DEFAULT]
user=$OCI_USER_OCID
fingerprint=$OCI_FINGERPRINT
key_file=/root/.oci/oci_api_key.pem
tenancy=$OCI_TENANT_OCID
region=$OCI_REGION
EOF

# --- TUS DATOS (Rellena esto) ---
MI_AD="TU_AD_AQUI"
MI_IMAGE_ID="TU_IMAGE_ID_AQUI"
MI_SUBNET_ID="TU_SUBNET_ID_AQUI"
MI_SSH_PUB="ssh-rsa AAAAB3NzaC... (TU CLAVE ENTERA) ...usuario"

# --- CORRECCIÓN: Guardamos la clave en un archivo ---
echo "$MI_SSH_PUB" > /root/key.pub

# --- BUCLE DE PESCA ---
echo "--- Iniciando Bot de Pesca Oracle ARM ---"

while true; do
    echo "[$(date +%T)] Lanzando anzuelo..."

    SALIDA=$(oci compute instance launch \
        --availability-domain "$MI_AD" \
        --compartment-id "$OCI_TENANT_OCID" \
        --shape "VM.Standard.A1.Flex" \
        --shape-config '{"ocpus":4,"memoryInGBs":24}' \
        --image-id "$MI_IMAGE_ID" \
        --subnet-id "$MI_SUBNET_ID" \
        --assign-public-ip true \
        --display-name "MiServidorGratis" \
        --ssh-authorized-keys-file "/root/key.pub" 2>&1)

    if [[ $? -eq 0 ]]; then
        echo "¡ÉXITO! SERVIDOR CREADO"
        echo "$SALIDA"
        sleep infinity
    else
        # Filtro de errores
        if [[ "$SALIDA" == *"Out of capacity"* ]] || [[ "$SALIDA" == *"500"* ]] || [[ "$SALIDA" == *"InternalError"* ]] || [[ "$SALIDA" == *"TooManyRequests"* ]]; then
            echo "Sin capacidad. Reintentando en 60s..."
        else
            echo "ERROR: $SALIDA"
            sleep 60
        fi
    fi
    sleep 60
done
