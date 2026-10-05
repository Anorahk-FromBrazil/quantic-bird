#!/bin/bash

# ==========================================
# Gerador de Docker Compose - NetBird + TCP Proxy
# ==========================================

COMPOSE_FILE="docker-compose.yml"

clear

echo "=========================================="
echo "|     Quantic Bird - A NetBird Stack     |"
echo "|      - Desenvolvido por Matheus Gomes  |"
echo "=========================================="
echo

# ==========================================
# Verifica se o NetBird Client já está rodando
# ==========================================

echo "Verificando NetBird Client..."
echo

NETBIRD_RUNNING=$(docker ps --filter "name=^/quantic-netbird-client$" --filter "status=running" -q)

if [[ -n "$NETBIRD_RUNNING" ]]; then

    echo "NetBird Client já está rodando."
    echo
    echo "Container: quantic-netbird-client"
    echo

    read -rp "Deseja continuar mesmo assim? [s/N]: " CONTINUE

    if [[ ! "$CONTINUE" =~ ^[Ss]$ ]]; then
        echo
        echo "Operação cancelada."
        exit 0
    fi

    NETBIRD_EXISTS=true

else

    echo "Nenhum NetBird Client rodando."
    echo

    # ==========================================
    # Configuração do NetBird
    # ==========================================

    read -rp "Hostname do NetBird: " NETBIRD_HOSTNAME
    read -rp "NB_SETUP_KEY: " NETBIRD_SETUP_KEY

    # Validação básica

    if [[ -z "$NETBIRD_HOSTNAME" || -z "$NETBIRD_SETUP_KEY" ]]; then
        echo
        echo "ERRO: hostname e NB_SETUP_KEY são obrigatórios."
        exit 1
    fi

    NETBIRD_EXISTS=false

    echo
    echo "Configuração do NetBird:"
    echo "  Hostname: $NETBIRD_HOSTNAME"
    echo "  Setup Key: $NETBIRD_SETUP_KEY"
    echo

fi


# ==========================================
# Arrays para armazenar as configurações
# ==========================================

declare -a PORTS
declare -a COMMANDS


# ==========================================
# Configuração do TCP Proxy
# ==========================================

while true; do

    echo
    echo "=========================================="
    echo "     Criando novo redirecionamento"
    echo "=========================================="
    echo

    read -rp "IP de destino: " DEST_IP
    read -rp "Porta TCP-LISTEN (entrada): " LISTEN_PORT
    read -rp "Porta de destino: " DEST_PORT

    # Validação básica

    if [[ -z "$DEST_IP" || -z "$LISTEN_PORT" || -z "$DEST_PORT" ]]; then

        echo
        echo "ERRO: todos os campos são obrigatórios."
        continue

    fi

    # ==========================================
    # Guarda a porta para o ports:
    # ==========================================

    PORTS+=("$LISTEN_PORT")

    # ==========================================
    # Cria o comando socat
    # ==========================================

    COMMANDS+=("socat TCP-LISTEN:${LISTEN_PORT},reuseaddr,fork TCP:${DEST_IP}:${DEST_PORT} &")

    echo
    echo "Redirecionamento adicionado:"
    echo "  0.0.0.0:${LISTEN_PORT} -> ${DEST_IP}:${DEST_PORT}"
    echo

    read -rp "Deseja adicionar outro redirecionamento? [S/n]: " ADD_MORE

    if [[ "$ADD_MORE" =~ ^[Nn]$ ]]; then
        break
    fi

done


# ==========================================
# Gerando Docker Compose
# ==========================================

echo
echo "Gerando ${COMPOSE_FILE}..."
echo


# ==========================================
# Cabeçalho
# ==========================================

cat > "$COMPOSE_FILE" <<EOF
services:

EOF


# ==========================================
# NetBird Client
# ==========================================

if [[ "$NETBIRD_EXISTS" = false ]]; then

cat >> "$COMPOSE_FILE" <<EOF
  netbird-client:

    container_name: quantic-netbird-client

    hostname: ${NETBIRD_HOSTNAME}

    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
      - SYS_RESOURCE

    devices:
      # Required when using userspace mode or when kernel module is not available
      - /dev/net/tun

    network_mode: host

    environment:
      - NB_SETUP_KEY=${NETBIRD_SETUP_KEY}

    volumes:
      - netbird-client:/var/lib/netbird

    image: netbirdio/netbird:latest


EOF

fi


# ==========================================
# TCP Proxy
# ==========================================

cat >> "$COMPOSE_FILE" <<EOF
  tcp-proxy:

    image: alpine/socat

    container_name: quantic-proxy

    restart: unless-stopped

    ports:
EOF


# ==========================================
# Adiciona as portas
# ==========================================

for PORT in "${PORTS[@]}"; do

    echo "      - \"${PORT}:${PORT}\"" >> "$COMPOSE_FILE"

done


# ==========================================
# Adiciona os comandos socat
# ==========================================

cat >> "$COMPOSE_FILE" <<EOF

    command:
      - sh
      - -c
      - |
EOF


for CMD in "${COMMANDS[@]}"; do

    echo "        ${CMD}" >> "$COMPOSE_FILE"

done


cat >> "$COMPOSE_FILE" <<EOF

        wait


volumes:

EOF


# ==========================================
# Volume do NetBird
# ==========================================

if [[ "$NETBIRD_EXISTS" = false ]]; then

cat >> "$COMPOSE_FILE" <<EOF
  netbird-client:
    name: quantic-netbird-client
EOF

fi


# ==========================================
# Resultado
# ==========================================

clear

echo
echo "=========================================="
echo "   Docker Compose criado com sucesso!"
echo "=========================================="
echo
docker compose up -d
docker compose ps
