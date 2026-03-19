#!/bin/bash

# --- Configurazione e Error Handling ---
set -e
trap 'echo "⚠️ Errore alla riga $LINENO. Assicurati di avere i permessi o che i dati siano corretti."' ERR

if [[ $EUID -ne 0 ]]; then
   echo "❌ Esegui come root: sudo $0"
   exit 1
fi

# --- Funzioni di Sistema ---
install_deps() {
    local apps=("nginx" "certbot" "openssl")
    local missing=()
    for app in "${apps[@]}"; do
        if ! command -v "$app" &> /dev/null; then missing+=("$app"); fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo "🔄 Installazione dipendenze..."
        apt update && apt install -y "${missing[@]}" python3-certbot-nginx
    fi
}

list_sites() {
    echo -e "\n--- Siti Configurati ---"
    local sites=(/etc/nginx/sites-enabled/*)
    if [ -e "${sites[0]}" ]; then
        for site in "${sites[@]}"; do
            domain=$(basename "$site")
            target=$(grep -m 1 "proxy_pass" "$site" | awk '{print $2}' | sed 's/;//')
            echo "🌐 $domain  -->  $target"
        done
    else
        echo "Nessun sito attivo."
    fi
    echo ""
}

remove_site() {
    list_sites
    read -p "Inserisci il dominio da rimuovere: " DOMAIN
    if [ -f "/etc/nginx/sites-available/$DOMAIN" ]; then
        rm -f "/etc/nginx/sites-enabled/$DOMAIN"
        rm -f "/etc/nginx/sites-available/$DOMAIN"
        rm -rf "/etc/nginx/ssl/$DOMAIN"
        echo "🗑️  Configurazione e certificati locali per $DOMAIN rimossi."
        nginx -t && systemctl reload nginx
    else
        echo "❌ Dominio non trovato."
    fi
}

add_site() {
    echo "--- Nuovo Reverse Proxy ---"
    read -p "Dominio (es. app.tuosito.it): " DOMAIN
    read -p "Target Locale (default 127.0.0.1): " L_HOST
    L_HOST=${L_HOST:-127.0.0.1}
    read -p "Porta Locale: " L_PORT

    # SSL Temporaneo
    mkdir -p "/etc/nginx/ssl/$DOMAIN"
    openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
      -keyout "/etc/nginx/ssl/$DOMAIN/selfsigned.key" \
      -out "/etc/nginx/ssl/$DOMAIN/selfsigned.crt" \
      -subj "/CN=$DOMAIN"

    # Configurazione
    cat <<EOF > "/etc/nginx/sites-available/$DOMAIN"
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name $DOMAIN;
    ssl_certificate /etc/nginx/ssl/$DOMAIN/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN/selfsigned.key;

    location / {
        proxy_pass http://$L_HOST:$L_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/"
    [ -f /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl restart nginx
    
    read -p "Vuoi attivare Let's Encrypt ora? (y/n): " LE
    if [[ "$LE" == "y" ]]; then
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
    fi
}

# --- Menu Principale ---
install_deps
while true; do
    echo "=============================="
    echo "   NGINX REVERSE PROXY MGR"
    echo "=============================="
    echo "1) Elenca Siti"
    echo "2) Aggiungi Nuovo Proxy"
    echo "3) Rimuovi Proxy"
    echo "4) Esci"
    read -p "Scegli un'opzione: " OPT
    case $OPT in
        1) list_sites ;;
        2) add_site ;;
        3) remove_site ;;
        4) exit 0 ;;
        *) echo "Scelta non valida." ;;
    esac
done
