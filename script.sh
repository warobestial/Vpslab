#!/bin/bash

# --- 1. CONFIGURACIÓN DE CREDENCIALES (Vienen de Easypanel) ---
mkdir -p /root/.oci
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

# --- 2. TUS DATOS (Rellena esto con lo que conseguiste) ---

# Tu Availability Domain (Ej: GwTz:US-PHOENIX-1-AD-1)
MI_AD="gGeD:PHX-AD-1"

# El ID de la imagen Ubuntu (Ej: ocid1.image...)
MI_IMAGE_ID="ocid1.image.oc1.phx.aaaaaaaaza55imglrnzcwthxmyh7w7mato5vgqqh7r3mhfwe3444utjafcva"

# El ID de tu Subred Publica (Ej: ocid1.subnet...)
MI_SUBNET_ID="ocid1.subnet.oc1.phx.aaaaaaaapgcgg7gg6gxbefzsusri2jo3zc256nm6xbece2g64enz2y7y7qvq"

# Tu clave pública SSH completa (Empieza por ssh-rsa... y acaba con tu correo o nombre)
MI_SSH_PUB="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaObOHcGRs2U8At7kQGv8kGAjG3Cogce8UPUbUGtcvNTMzI5HhM2ZYpxSyWx5ob/uCzXlHbiqNJBWAK2rg8maLJhv6or8g2TXERM5RpMpR4jjNTtrQuVeo7ZiIP2/rwt4IqJOZTI6XA8TMWl1gA0CTqBZ/BDRWg2pSBa0WZHoT84qKjfZZdL6PHap08p4ZdeQMTkD0sx3p43YCD9/VHIQ3Wau0OM+DJtqadSo3fLw7vdW7max4lG34v1EOHmzUEF3mGewCQDSzlPLCc18FXsBl/sRrx4/r4oGv+utTfskyEHDELQIpkjbCuKk87WRTQJoxHR1U9uSVBdRzXGo8U7sB warobestia@3d0b6461cce2"


# --- 3. BUCLE DE INTENTOS (No toques nada aquí abajo) ---
echo "--- Iniciando Bot de Pesca Oracle ARM ---"

while true; do
    echo "[$(date +%T)] Lanzando anzuelo..."

    # Ejecutamos la solicitud con tus datos
    SALIDA=$(oci compute instance launch \
        --availability-domain "$MI_AD" \
        --compartment-id "$OCI_TENANT_OCID" \
        --shape "VM.Standard.A1.Flex" \
        --shape-config '{"ocpus":4,"memoryInGBs":24}' \
        --image-id "$MI_IMAGE_ID" \
        --subnet-id "$MI_SUBNET_ID" \
        --assign-public-ip true \
        --display-name "MiServidorGratis" \
        --ssh-authorized-keys-value "$MI_SSH_PUB" 2>&1)

    # Verificamos si hubo éxito
    if [[ $? -eq 0 ]]; then
        echo "#############################################"
        echo "¡ÉXITO! ¡SERVIDOR CREADO!"
        echo "#############################################"
        echo "$SALIDA"
        # Dormir para siempre para mantener el log visible
        sleep infinity
    else
        # Filtramos errores comunes
        if [[ "$SALIDA" == *"Out of capacity"* ]] || [[ "$SALIDA" == *"500"* ]] || [[ "$SALIDA" == *"InternalError"* ]] || [[ "$SALIDA" == *"TooManyRequests"* ]]; then
            echo "Sin capacidad o error temporal. Reintentando en 60s..."
        else
            echo "¡ERROR DE CONFIGURACIÓN! Revisa tus IDs:"
            echo "$SALIDA"
            # Espera larga para no saturar el log si hay error grave
            sleep 300
        fi
    fi
    sleep 60
done
