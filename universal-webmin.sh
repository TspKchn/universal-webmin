#!/bin/bash
# universal-webmin-auto-stable.sh
# Universal Webmin Installer/Updater + Auto SSL (Fixed miniserv.pl & Path Watch)
# By ChatGPT (Stable Edition)

set -e

echo "===== Universal Webmin Installer (Stable + Auto-SSL, Fixed miniserv.pl) ====="

# --- Update & install dependencies ---
apt-get update -y && apt-get upgrade -y
apt-get install -y wget curl perl libnet-ssleay-perl openssl \
libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python gnupg

# --- Detect Webmin version ---
INSTALLED_VERSION="None"
if [ -f /usr/share/webmin/version ]; then
    INSTALLED_VERSION=$(cat /usr/share/webmin/version)
fi
echo "[INFO] Installed Webmin version: $INSTALLED_VERSION"

# --- Get latest version from SourceForge ---
LATEST_VERSION=$(curl -s https://sourceforge.net/projects/webadmin/files/webmin/ | \
grep -oP 'webmin/\K[0-9]+\.[0-9]+' | sort -V | tail -1)
echo "[INFO] Latest Webmin version: $LATEST_VERSION"

UPDATE_FLAG=false
if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
    UPDATE_FLAG=true
fi

# --- Download & install ---
if [ "$UPDATE_FLAG" = true ]; then
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    DOWNLOAD_URL="https://sourceforge.net/projects/webadmin/files/webmin/$LATEST_VERSION/webmin_${LATEST_VERSION}_all.deb/download"
    echo "[INFO] Downloading Webmin $LATEST_VERSION..."
    wget -q -O webmin_latest.deb "$DOWNLOAD_URL"
    echo "[INFO] Installing Webmin..."
    dpkg -i webmin_latest.deb || apt --fix-broken install -y
    rm -rf "$TMPDIR"
else
    echo "[INFO] Webmin already up-to-date."
fi

# --- Configuration paths ---
MINISERV_CONF="/etc/webmin/miniserv.conf"
WEBMIN_SSL_DIR="/etc/ssl/webmin"
SSL_CERT="/etc/ssl/universal-vpn/fullchain.cer"
SSL_KEY="/etc/ssl/universal-vpn/private.key"
PEM_FILE="$WEBMIN_SSL_DIR/miniserv.pem"
SELF_KEY="$WEBMIN_SSL_DIR/miniserv.key"

mkdir -p "$WEBMIN_SSL_DIR"

# --- Force Webmin port to 10000 ---
if [ -f "$MINISERV_CONF" ]; then
    sed -i 's/^port=.*/port=10000/' "$MINISERV_CONF"
fi

# --- Generate fallback self-signed cert if universal-vpn not ready ---
if [[ ! -f "$SSL_CERT" || ! -f "$SSL_KEY" ]]; then
    echo "[WARN] universal-vpn cert not found, generating self-signed cert..."
    openssl req -new -x509 -days 3650 -nodes \
        -out "$PEM_FILE" -keyout "$SELF_KEY" \
        -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Home/OU=IT/CN=localhost"
    cat "$SELF_KEY" >> "$PEM_FILE"
else
    echo "[INFO] Found universal-vpn SSL — combining key and certificate..."
    cat "$SSL_KEY" "$SSL_CERT" > "$PEM_FILE"
fi

chmod 600 "$PEM_FILE"
chown root:root "$PEM_FILE"

# --- Apply to miniserv.conf ---
if [ -f "$MINISERV_CONF" ]; then
    sed -i "s|^ssl=.*|ssl=1|" "$MINISERV_CONF"
    sed -i "s|^keyfile=.*|keyfile=$PEM_FILE|" "$MINISERV_CONF"
    sed -i "s|^certfile=.*|certfile=$PEM_FILE|" "$MINISERV_CONF"
else
    echo "[WARN] miniserv.conf not found, Webmin config may not be initialized yet."
fi

# --- Enable and restart Webmin safely ---
systemctl daemon-reexec || true
systemctl enable webmin
systemctl restart webmin || systemctl start webmin
sleep 3

if ! systemctl is-active --quiet webmin; then
    echo "[ERROR] Webmin failed to start. For details: journalctl -u webmin -n 20"
else
    echo "[OK] Webmin is running and SSL loaded successfully."
fi

# --- Setup auto SSL reload script ---
AUTO_SSL_SCRIPT="/usr/local/bin/webmin-auto-ssl.sh"
cat << 'EOF' > "$AUTO_SSL_SCRIPT"
#!/bin/bash
WEBMIN_SSL_DIR="/etc/ssl/webmin"
SSL_CERT="/etc/ssl/universal-vpn/fullchain.cer"
SSL_KEY="/etc/ssl/universal-vpn/private.key"
PEM_FILE="$WEBMIN_SSL_DIR/miniserv.pem"

if [[ -f "$SSL_CERT" && -f "$SSL_KEY" ]]; then
    echo "[INFO] Updating Webmin SSL..."
    cat "$SSL_KEY" "$SSL_CERT" > "$PEM_FILE"
    chmod 600 "$PEM_FILE"
    chown root:root "$PEM_FILE"
    systemctl restart webmin
else
    echo "[WARN] SSL files missing — skipping Webmin reload."
fi
EOF

chmod +x "$AUTO_SSL_SCRIPT"

# --- Systemd .path and .service ---
cat << EOF > /etc/systemd/system/webmin-auto-ssl.service
[Unit]
Description=Reload Webmin SSL when universal-vpn certificate changes

[Service]
Type=oneshot
ExecStart=$AUTO_SSL_SCRIPT
EOF

cat << EOF > /etc/systemd/system/webmin-auto-ssl.path
[Unit]
Description=Watch for universal-vpn-cert SSL updates for Webmin

[Path]
PathExists=/etc/ssl/universal-vpn/fullchain.cer
PathExists=/etc/ssl/universal-vpn/private.key

[Install]
WantedBy=multi-user.target
EOF

# --- Enable watcher ---
systemctl daemon-reload
systemctl enable --now webmin-auto-ssl.path

echo
echo "===== Webmin Installation + Auto-SSL (Stable Edition) Completed ====="
echo "✅ Webmin URL: https://<your-ip>:10000"
echo "🔁 SSL auto-updates whenever universal-vpn-cert renews."
echo "🛠 Log check: journalctl -u webmin -n 20"
