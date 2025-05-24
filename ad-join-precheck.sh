#!/bin/bash

set -e

# ANSI color codes
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Helper functions
function info() {
  echo -e "${YELLOW}[INFO]${RESET} $1"
}

function success() {
  echo -e "${GREEN}[OK]${RESET} $1"
}

function error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

# Ask for domain and FQDN of AD server
read -rp "Enter Active Directory domain (e.g., fuga.example.com): " AD_DOMAIN
read -rp "Enter AD domain controller FQDN (e.g., hoge.fuga.example.com): " AD_DC_FQDN

# 1. Check if already joined
info "Checking if this host is already joined to a domain..."
if realm list | grep -q "realm-name"; then
  error "This machine appears to already be joined to a domain."
  realm list
  exit 1
else
  success "Not joined to any domain."
fi

# 2. Check FQDN
info "Checking FQDN configuration..."
if [[ "$(hostname -f)" == *.* ]]; then
  success "FQDN is properly set: $(hostname -f)"
else
  error "FQDN is not set properly. hostname -f = $(hostname -f)"
  exit 1
fi

# 3. Ping check
info "Pinging AD domain controller ($AD_DC_FQDN)..."
if ping -c 2 "$AD_DC_FQDN" > /dev/null 2>&1; then
  success "Ping successful."
else
  error "Ping to $AD_DC_FQDN failed."
  exit 1
fi

# 4. DNS port check (UDP and TCP 53)
info "Checking DNS port accessibility (TCP/UDP 53)..."
echo | nc -vz -w 2 "$AD_DC_FQDN" 53 && success "TCP/53 is open." || error "TCP/53 is not accessible."

if timeout 2 bash -c "</dev/udp/$AD_DC_FQDN/53" 2>/dev/null; then
  success "UDP/53 is accessible."
else
  error "UDP/53 is not accessible."
fi

# 5. /etc/resolv.conf includes AD DNS?
info "Checking if AD server is listed in /etc/resolv.conf..."
if grep -q "$AD_DC_FQDN" /etc/resolv.conf || grep -q "$(getent ahosts $AD_DC_FQDN | awk '{ print $1 }' | head -n 1)" /etc/resolv.conf; then
  success "AD DNS appears in /etc/resolv.conf."
else
  error "AD DNS is not listed in /etc/resolv.conf."
fi

# 6. SRV record lookup
info "Checking SRV record for _ldap._tcp.$AD_DOMAIN..."
if dig +short _ldap._tcp.$AD_DOMAIN SRV | grep -q "$AD_DC_FQDN"; then
  success "SRV record resolves correctly."
else
  error "SRV record lookup failed or does not match expected AD DC."
fi

# 7. Required packages
REQUIRED_PKGS=(sssd oddjob oddjob-mkhomedir adcli samba-common-tools realmd)
info "Checking required packages..."
for pkg in "${REQUIRED_PKGS[@]}"; do
  if rpm -q "$pkg" > /dev/null 2>&1; then
    success "$pkg is installed."
  else
    error "$pkg is NOT installed."
  fi
fi

# 8. Check chronyd (time sync is critical for Kerberos)
info "Checking if chronyd (time sync) is active..."
if systemctl is-active chronyd > /dev/null 2>&1; then
  success "chronyd is active."
else
  error "chronyd is not active. Kerberos may fail without accurate time sync."
fi

# 9. Additional notes for nsswitch.conf and pam.d
info "Post-join steps include updating nsswitch.conf and pam.d files."
echo -e "${YELLOW}These are often handled automatically via 'authselect select sssd'${RESET}"
echo -e "${YELLOW}Ensure nsswitch.conf includes 'sss' for passwd, group, etc., and pam.d reflects SSSD settings.${RESET}"

success "All checks completed. Review warnings and proceed accordingly."
exit 0
