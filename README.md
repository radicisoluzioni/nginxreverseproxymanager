# 🔀 Nginx Reverse Proxy Manager

> Strumento interattivo da riga di comando per gestire configurazioni Nginx reverse proxy su sistemi Linux.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux%20%28Debian%2FUbuntu%29-orange.svg)](https://ubuntu.com/)

---

## 📋 Indice

- [Descrizione](#-descrizione)
- [Funzionalità](#-funzionalità)
- [Requisiti](#-requisiti)
- [Installazione](#-installazione)
- [Utilizzo](#-utilizzo)
- [Come funziona](#-come-funziona)
- [Configurazione generata](#-configurazione-nginx-generata)
- [Licenza](#-licenza)

---

## 📖 Descrizione

**Nginx Reverse Proxy Manager** è uno script Bash interattivo che semplifica la gestione delle configurazioni Nginx come reverse proxy. Elimina la necessità di editare manualmente i file di configurazione di Nginx, automatizzando la creazione, il listing e la rimozione di proxy con supporto SSL integrato.

---

## ✨ Funzionalità

- 📋 **Lista siti** — visualizza tutti i reverse proxy attivi con i rispettivi target
- ➕ **Aggiunta proxy** — crea nuove configurazioni reverse proxy in modo interattivo
- 🗑️ **Rimozione proxy** — elimina configurazioni e certificati SSL associati
- 🔒 **SSL automatico** — genera certificati self-signed (validità 30 giorni) durante la configurazione
- 🌐 **Let's Encrypt** — integrazione opzionale con Certbot per certificati validi
- 🔄 **Redirect HTTP → HTTPS** — configurazione automatica del redirect 301
- 🔌 **Supporto WebSocket** — headers `Upgrade` e `Connection` inclusi di default
- 📦 **Installazione dipendenze** — verifica e installa automaticamente nginx, certbot e openssl
- ⚠️ **Error handling** — trap degli errori con messaggi informativi

---

## 🛠️ Requisiti

| Requisito | Dettaglio |
|-----------|-----------|
| **Sistema Operativo** | Linux (Debian/Ubuntu o derivati) |
| **Permessi** | Root / sudo |
| **Shell** | Bash 4+ |
| **Internet** | Necessario per Let's Encrypt e installazione dipendenze |

Le dipendenze seguenti vengono installate automaticamente se mancanti:

- `nginx`
- `certbot`
- `openssl`
- `python3-certbot-nginx`

---

## 🚀 Installazione

```bash
# Clona il repository
git clone https://github.com/radicisoluzioni/nginxreverseproxymanager.git
cd nginxreverseproxymanager

# Rendi lo script eseguibile
chmod +x nginx-manager.sh
```

---

## 🖥️ Utilizzo

Esegui lo script come root:

```bash
sudo ./nginx-manager.sh
```

All'avvio viene presentato il menu principale:

```
==============================
   NGINX REVERSE PROXY MGR
==============================
1) Elenca Siti
2) Aggiungi Nuovo Proxy
3) Rimuovi Proxy
4) Esci
Scegli un'opzione:
```

### 1️⃣ Elenca Siti

Mostra tutti i siti attivi in `/etc/nginx/sites-enabled/` con il rispettivo proxy target:

```
--- Siti Configurati ---
🌐 app.miosito.it  -->  http://127.0.0.1:3000
🌐 api.miosito.it  -->  http://127.0.0.1:8080
```

### 2️⃣ Aggiungi Nuovo Proxy

Guida interattiva per creare un nuovo reverse proxy:

```
--- Nuovo Reverse Proxy ---
Dominio (es. app.tuosito.it): app.miosito.it
Target Locale (default 127.0.0.1): 127.0.0.1
Porta Locale: 3000
```

Al termine viene chiesto se attivare Let's Encrypt:

```
Vuoi attivare Let's Encrypt ora? (y/n): y
```

### 3️⃣ Rimuovi Proxy

Elenca i siti attivi e chiede quale rimuovere:

```
Inserisci il dominio da rimuovere: app.miosito.it
🗑️  Configurazione e certificati locali per app.miosito.it rimossi.
```

---

## ⚙️ Come funziona

1. **Controllo permessi** — lo script verifica di essere eseguito come root.
2. **Installazione dipendenze** — controlla la presenza di nginx, certbot e openssl; se mancanti li installa via `apt`.
3. **Aggiunta sito**:
   - Genera un certificato SSL self-signed (RSA 2048-bit, 30 giorni) con OpenSSL.
   - Scrive la configurazione Nginx in `/etc/nginx/sites-available/<DOMAIN>`.
   - Crea il symlink in `/etc/nginx/sites-enabled/`.
   - Rimuove il sito `default` di Nginx se presente.
   - Ricarica Nginx con `systemctl restart nginx`.
   - (Opzionale) Esegue Certbot per sostituire il certificato self-signed con uno Let's Encrypt.
4. **Rimozione sito**:
   - Elimina i file in `sites-available`, `sites-enabled` e la directory SSL.
   - Ricarica Nginx con `systemctl reload nginx`.

---

## 📄 Configurazione Nginx generata

Per ogni sito vengono creati due server block:

```nginx
# Redirect HTTP → HTTPS
server {
    listen 80;
    server_name app.miosito.it;
    return 301 https://$host$request_uri;
}

# HTTPS con Reverse Proxy
server {
    listen 443 ssl;
    server_name app.miosito.it;
    ssl_certificate     /etc/nginx/ssl/app.miosito.it/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/app.miosito.it/selfsigned.key;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**Percorsi utilizzati:**

| Percorso | Descrizione |
|----------|-------------|
| `/etc/nginx/sites-available/<DOMAIN>` | File di configurazione Nginx |
| `/etc/nginx/sites-enabled/<DOMAIN>` | Symlink al file di configurazione |
| `/etc/nginx/ssl/<DOMAIN>/` | Certificati SSL (self-signed o Let's Encrypt) |

---

## 📜 Licenza

Questo progetto è distribuito sotto licenza **GNU General Public License v3.0**.
Consulta il file [LICENSE](LICENSE) per i dettagli completi.

---

<p align="center">Sviluppato da <a href="https://github.com/radicisoluzioni">Radici Soluzioni</a></p>
