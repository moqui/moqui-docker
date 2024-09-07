#!/bin/bash

# Set Moqui setup directory
MOQUI_SETUP_DIR="/opt/moqui"

# Check if $MOQUI_SETUP_DIR exists; if not, clone the repository
if [ ! -d "$MOQUI_SETUP_DIR" ]; then
  echo "Cloning Moqui Docker repository..."
  git clone https://github.com/moqui/moqui-docker.git "$MOQUI_SETUP_DIR"
fi

cd "$MOQUI_SETUP_DIR" || exit 1

# Function to validate domain
validate_domain() {
  if [[ "$1" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt for domain if not provided as a parameter
DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  read -rp "Enter the domain to run Moqui on: " DOMAIN
fi

# Validate the domain
while ! validate_domain "$DOMAIN"; do
  echo "Invalid domain. Please enter a valid domain for ACME HTTP verification."
  read -rp "Enter a valid domain: " DOMAIN
done

# Prompt for ACME email
read -rp "Enter your ACME email address: " ACME_EMAIL

# Set environment variables
echo "Setting environment variables..."

export VIRTUAL_HOST="$DOMAIN"
export DEFAULT_HOST="$DOMAIN"
export DEFAULT_EMAIL="$ACME_EMAIL"
export LETSENCRYPT_TEST=true

# Generate passwords for sensitive environment variables
POSTGRES_PASSWORD=$(openssl rand -base64 16)
ENTITY_DS_CRYPT_PASS=$(openssl rand -base64 16)
ELASTICSEARCH_PASSWORD=$(openssl rand -base64 16)

# Save the environment variables to a .env file
cat <<EOF > .env
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENTITY_DS_CRYPT_PASS=$ENTITY_DS_CRYPT_PASS
ELASTICSEARCH_PASSWORD=$ELASTICSEARCH_PASSWORD
VIRTUAL_HOST=$VIRTUAL_HOST
DEFAULT_HOST=$DEFAULT_HOST
DEFAULT_EMAIL=$DEFAULT_EMAIL
LETSENCRYPT_TEST=$LETSENCRYPT_TEST
EOF

echo "Environment setup complete. Configuration saved in .env file."
