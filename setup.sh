#!/bin/bash

# Set Moqui setup directory
MOQUI_SETUP_DIR="/opt/moqui"

if ! [ -x "$(command -v docker)" ]; then
  echo 'Docker is not installed. Please install Docker by running...'

  # Download the convenience script
  echo "curl -fsSL https://get.docker.com -o get-docker.sh"

  # Run the convenience script
  echo "sh get-docker.sh"

  # Clean up
  echo "rm get-docker.sh"
  exit 1
else
  echo 'Docker is already installed.'
fi

# Ensure that the docker daemon is running
if ! systemctl is-active --quiet docker; then
  echo 'Please start Docker service by running...'
  echo "systemctl start docker"
fi

# Check if $MOQUI_SETUP_DIR exists; if not, clone the repository
if [ -n "$1" ]; then
  MOQUI_SETUP_DIR="$1"
elif [ -n "$MOQUI_SETUP_DIR" ]; then
  echo "Using environment variable MOQUI_SETUP_DIR: $MOQUI_SETUP_DIR"
else
  read -p "Enter the directory path for Moqui setup (default: 'moqui'): " USER_INPUT

  # If the user didn't provide input, set a default value
  if [ -z "$USER_INPUT" ]; then
    if [ -d "moqui" ]; then
      # Generate a random string with a prefix of 'moqui-'
      RANDOM_SUFFIX=$(openssl rand -hex 4)
      MOQUI_SETUP_DIR="moqui-$RANDOM_SUFFIX"
      echo "Defaulting to generated directory: $MOQUI_SETUP_DIR"
    else
      MOQUI_SETUP_DIR="moqui"
      echo "Defaulting to directory: $MOQUI_SETUP_DIR"
    fi
  else
    MOQUI_SETUP_DIR="$USER_INPUT"
  fi
fi

curl -v https://github.com/moqui/moqui-docker.zip -o "$MOQUI_SETUP_DIR".zip
unzip "$MOQUI_SETUP_DIR".zip -d "$MOQUI_SETUP_DIR"

# TODO: validate domain for acme http verification

# Load existing .env file if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Prompt for domain if not provided as a parameter
DOMAIN=${1:-$VIRTUAL_HOST}
if [ -z "$DOMAIN" ]; then
  read -rp "Enter the domain to run Moqui: " input
  DOMAIN=${input:-DOMAIN}
  DOMAIN=${DOMAIN:-$VIRTUAL_HOST}
else
  read -rp "Enter the domain to run Moqui [$VIRTUAL_HOST]: " input
  DOMAIN=${input:-DOMAIN}
  DOMAIN=${DOMAIN:-$VIRTUAL_HOST}
fi

# Validate the domain
#while ! validate_domain "$DOMAIN"; do
#  echo "Invalid domain. Please enter a valid domain for ACME HTTP verification."
#  read -rp "Enter a valid domain: " DOMAIN
#done

# Set ACME_EMAIL to the second positional parameter or keep its current value
ACME_EMAIL=${2:-$ACME_EMAIL}
# Prompt for ACME_EMAIL if it is still empty
if [ -z "$ACME_EMAIL" ]; then
  read -rp "Enter your ACME email address: " ACME_EMAIL
else
  read -rp "Enter your ACME email address [$ACME_EMAIL]: " input
  # If the user input is empty, retain the current value of ACME_EMAIL
  ACME_EMAIL=${input:-$ACME_EMAIL}
fi

# Set environment variables
echo "Setting environment variables..."

export VIRTUAL_HOST="$DOMAIN"
export DEFAULT_HOST="$DOMAIN"
export DEFAULT_EMAIL="$ACME_EMAIL"
export LETSENCRYPT_TEST=true

# Set default passwords or prompt for them if not provided
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(head -c 16 /dev/random | base64)}
read -rp "Enter your PostgreSQL password [$POSTGRES_PASSWORD]: " input
POSTGRES_PASSWORD=${input:-$POSTGRES_PASSWORD}

ENTITY_DS_CRYPT_PASS=${ENTITY_DS_CRYPT_PASS:-$(head -c 16 /dev/random | base64)}
read -rp "Enter your Entity DS Crypt password [$ENTITY_DS_CRYPT_PASS]: " input
ENTITY_DS_CRYPT_PASS=${input:-$ENTITY_DS_CRYPT_PASS}

ELASTICSEARCH_PASSWORD=${ELASTICSEARCH_PASSWORD:-$(head -c 16 /dev/random | base64)}
read -rp "Enter your Elasticsearch password [$ELASTICSEARCH_PASSWORD]: " input
ELASTICSEARCH_PASSWORD=${input:-$ELASTICSEARCH_PASSWORD}

MOQUI_IMAGE=${MOQUI_IMAGE:-moqui/moquidemo}
read -rp "Enter your moqui image [$MOQUI_IMAGE]: " input
$MOQUI_IMAGE=${input:-$MOQUI_IMAGE}


# Save the environment variables to a .env file
cat <<EOF > .env
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENTITY_DS_CRYPT_PASS=$ENTITY_DS_CRYPT_PASS
ELASTICSEARCH_PASSWORD=$ELASTICSEARCH_PASSWORD
VIRTUAL_HOST=$VIRTUAL_HOST
DEFAULT_HOST=$DEFAULT_HOST
DEFAULT_EMAIL=$DEFAULT_EMAIL
LETSENCRYPT_TEST=$LETSENCRYPT_TEST
ACME_EMAIL=$ACME_EMAIL
MOQUI_IMAGE=$MOQUI_IMAGE
EOF

echo "Environment setup complete. Configuration saved in $MOQUI_SETUP_DIR/.env file."

# Check if there is the adequate docker image to run the docker compose

# Run ./compose-up default-compose.yml
# if it fails, run ./compose-down.sh default-compose.yml
./compose-up.sh default-compose.yml . eclipse-temurin:11-jdk .env
