#!/bin/bash

# --- 1. CONFIGURACIÓN DE CREDENCIALES (MÉTODO BASE64) ---
# Creamos la carpeta
mkdir -p /root/.oci

# Decodificamos la variable OCI_PRIVATE_KEY (que está en Base64) y la guardamos como archivo .pem
echo "$OCI_PRIVATE_KEY" | base64 -d > /root/.oci/oci_api_key.pem

# Damos los permisos estrictos necesarios (600)
chmod 600 /root/.oci/oci_api_key.pem

# Creamos el archivo de configuración de OCI
cat <<EOF > /root/.oci/config
[DEFAULT]
user=$OCI_USER_OCID
fingerprint=$OCI_FINGERPRINT
key_file=/root/.oci/oci_api_key.pem
tenancy=$OCI_TENANT_OCID
region=$OCI_REGION
EOF

# --- 2. TUS DATOS (¡EDITA ESTO!) ---

# Tu Availability Domain (Ej: GwTz:US-PHOENIX-1-AD-1)
MI_AD="gGeD:PHX-AD-1"

# El ID de la imagen Ubuntu (Ej: ocid1.image...)
MI_IMAGE_ID="ocid1.image.oc1.phx.aaaaaaaaza55imglrnzcwthxmyh7w7mato5vgqqh7r3mhfwe3444utjafcva"

# El ID de tu Subred Publica (Ej: ocid1.subnet...)
MI_SUBNET_ID="ocid1.subnet.oc1.phx.aaaaaaaapgcgg7gg6gxbefzsusri2jo3zc256nm6xbece2g64enz2y7y7qvq"

# Tu clave pública SSH completa (Empieza por ssh-rsa... o ssh-ed25519...)
MI_SSH_PUB="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsoOqEFgVkArPFesTXeALIwLzGLoh9phoHuSa5cr+aM78q7wizH1N801JZhFkr+3AQozhfk35NZT/bVLxdMMjXlsAdyLOGHsQGOPbwSOQ/ayJ5HrkPlyPCyKNuVP6TQz95aEurbxdeZg7C8RZuMxnjveCkyi3Ke/NKvFL8aeZr025AfW+P/TRjk70+PWUf/OmT+TvDcsZSQB2E4HLCYnFnzbF4u0RQT25MsDj7KyM+Q5a6p0bTK0J7g76e+ANes/+foV54JoUo/+Y+H6O/mgYT8M0eOWNpjdAYbBpfJ8MOxATbrNcIiQzimrY7r3dqRG3cqWmCM40emUfXVU0NHFUGCJLmIS2TnWe327iE0tGGTOaSrDzsHXgdDKsc+hXvlanZ9UVVt0Dp4K+cRTgYSCulLHrRo6c1vvG6hvGxI8XRcjKCjuDeE7hzpNwbtEGiS7vlEkI9CYIGbuCAbb4MqJp1enE84mhN+e/H0ZkKcpXi9ElPYSJzoENba6gPT7mHktds1tXFM5Zv6uJwrpIUIysBRvlN5CIVQlUdnGw++v/grKWECoPH5ht+lJPSf31mqLE67KW61e4ywjahcAgClYFk7HC9DqBSbazcg5hgjFfMd0WvwEP3s5bAspNpa/O3odGYmW5Ymym0pFXC3g6BfJbgazSBuZbtO6wQ8/VqSu9OcQ== waro@waro-Lenovo-ideapad-320-15ABR"


# --- 3. PREPARAR CLAVE SSH PARA EL COMANDO ---
# Oracle exige un archivo, no texto directo. Guardamos tu clave en un archivo temporal.
echo "$MI_SSH_PUB" > /root/key.pub


# --- 4. BUCLE DE PESCA INFINITO ---
echo "--- Iniciando Bot de Pesca Oracle ARM (Modo Base64) ---"

while true; do
    echo "[$(date +%T)] Lanzando anzuelo..."

    # Ejecutamos el comando OCI
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

    # Verificamos el resultado
    if [[ $? -eq 0 ]]; then
        echo "#############################################"
        echo "¡ÉXITO! ¡SERVIDOR CREADO!"
        echo "#############################################"
        echo "$SALIDA"
        # Si tiene éxito, el script se duerme para siempre (no sigue pidiendo)
        sleep infinity
    else
        # Filtramos errores conocidos para limpiar el log
        if [[ "$SALIDA" == *"Out of capacity"* ]] || [[ "$SALIDA" == *"500"* ]] || [[ "$SALIDA" == *"InternalError"* ]] || [[ "$SALIDA" == *"TooManyRequests"* ]]; then
            echo "Sin capacidad o error temporal. Reintentando en 60s..."
        else
            # Si es otro error, lo mostramos completo
            echo "ERROR TÉCNICO: $SALIDA"
            # Esperamos 60 segundos antes de reintentar
            sleep 60
        fi
    fi
    # Espera estándar entre intentos
    sleep 60
done
