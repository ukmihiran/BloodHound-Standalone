#!/bin/sh
set -eu

LOG_FILE="/var/log/bloodhound.log"

extract_password() {
  if [ -f "$LOG_FILE" ]; then
    line=$(grep -m1 'Initial Password Set To:' "$LOG_FILE" || true)
    if [ -n "${line:-}" ]; then
      pw=$(printf '%s' "$line" | awk -F'Initial Password Set To:' '{print $2}' | awk -F'#' '{print $1}' | tr -d ' \t\r\n')
      if [ -n "${pw:-}" ]; then
        echo "$pw"
        return 0
      fi
    fi
  fi
  return 1
}

echo "[password-display] Waiting for BloodHound setup password..."

# Wait up to 90 seconds for the password to appear in the log
for i in $(seq 1 90); do
  if pw=$(extract_password); then
    echo ""
    echo "==============================================================================="
    echo "  BLOODHOUND SETUP PASSWORD"
    echo ""
    echo "    $pw"
    echo ""
    echo "  URL: http://localhost:8080/ui/login"
    echo "  Note: This password is only valid for the initial setup."
    echo "==============================================================================="
    echo ""
    exit 0
  fi
  sleep 1
done

# Fallback: provide instructions to retrieve from logs
echo ""
echo "==============================================================================="
echo "  BLOODHOUND SETUP PASSWORD"
echo ""
echo "  Could not extract the password within the timeout."
echo "  Retrieve it from logs on the host with:"
echo ""
echo "    docker logs bloodhound-standalone | grep -i 'Initial Password Set To'"
echo ""
echo "  Then visit: http://localhost:8080/ui/login"
echo "==============================================================================="
echo ""

exit 0


