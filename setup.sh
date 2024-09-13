#!/bin/bash

# Set Moqui setup directory
MOQUI_SETUP_DIR="moqui"

if ! [ -x "$(command -v docker)" ]; then
  echo 'Docker is not installed. Please install Docker by running...'

  # Download the convenience script
  echo "curl -fsSL https://get.docker.com | sh"

  exit 1
else
  echo 'Docker is already installed.'
fi

# Ensure that the docker daemon is running
if ! systemctl is-active --quiet docker; then
  echo 'Please start Docker service by running...'
  echo "systemctl start docker"
  exit 1
fi

# Check if $MOQUI_SETUP_DIR exists; if not, clone the repository
if [ -n "$1" ]; then
  MOQUI_SETUP_DIR="$1"
elif [ -n "$MOQUI_SETUP_DIR" ]; then
  echo "Using environment variable MOQUI_SETUP_DIR: $MOQUI_SETUP_DIR"
else
  read -p "Enter the directory path for Moqui setup [$MOQUI_SETUP_DIR]: " USER_INPUT

  # If the user didn't provide input, set a default value
  if [ -z "$USER_INPUT" ]; then
    if [ -d "$MOQUI_SETUP_DIR" ]; then
      # Generate a random string with a prefix of 'moqui-'
      RANDOM_SUFFIX=$(openssl rand -hex 4)
      MOQUI_SETUP_DIR="moqui-$RANDOM_SUFFIX"
      echo "Defaulting to generated directory: $MOQUI_SETUP_DIR"
    fi
  else
    MOQUI_SETUP_DIR="$USER_INPUT"
  fi
fi

# Define the download URL for the .tar.gz version of the repository
DOWNLOAD_URL="https://github.com/moqui/moqui-docker/archive/refs/heads/master.tar.gz"

# Download the tar.gz file using curl
curl -sL "$DOWNLOAD_URL" -o "$MOQUI_SETUP_DIR.tar.gz"

# Ensure the `gunzip` command is available
if ! command -v gunzip &> /dev/null; then
  echo "gunzip could not be found. Please install gunzip and try again."
  exit 1
fi

# Create the directory if it doesn't exist
mkdir -p "$MOQUI_SETUP_DIR"

# Use gunzip to decompress the .tar.gz file
gunzip -q "$MOQUI_SETUP_DIR.tar.gz"

# Extract the resulting .tar file to the specified directory
tar -xf "$MOQUI_SETUP_DIR.tar" -C "$MOQUI_SETUP_DIR" --strip-components 1

# Remove the downloaded .tar file after extraction
rm "$MOQUI_SETUP_DIR.tar"

cd "$MOQUI_SETUP_DIR"

ls -lah

echo "Moqui Docker repository has been set up in $MOQUI_SETUP_DIR."

# Load existing .env file if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Prompt for domain if not provided as a parameter
DOMAIN=${1:-$VIRTUAL_HOST}
if [ -n "$DOMAIN" ]; then
  read -rp "Enter the domain to run Moqui: " input
  DOMAIN=${input:-DOMAIN}
  DOMAIN=${DOMAIN:-$VIRTUAL_HOST}
else
  read -rp "Enter the domain to run Moqui [$VIRTUAL_HOST]: " input
  DOMAIN=${input:-DOMAIN}
  DOMAIN=${DOMAIN:-$VIRTUAL_HOST}
fi

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
if [ -z "$POSTGRES_PASSWORD" ]; then
  POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(head -c 16 /dev/random | base64)}
  read -rp "Enter your PostgreSQL password [$POSTGRES_PASSWORD]: " input
  POSTGRES_PASSWORD=${input:-$POSTGRES_PASSWORD}
fi

if [ -z "$ENTITY_DS_CRYPT_PASS" ]; then
  ENTITY_DS_CRYPT_PASS=${ENTITY_DS_CRYPT_PASS:-$(head -c 16 /dev/random | base64)}
  read -rp "Enter your Entity DS Crypt password [$ENTITY_DS_CRYPT_PASS]: " input
  ENTITY_DS_CRYPT_PASS=${input:-$ENTITY_DS_CRYPT_PASS}
fi

if [ -z "$ELASTICSEARCH_PASSWORD" ]; then
  ELASTICSEARCH_PASSWORD=${ELASTICSEARCH_PASSWORD:-$(head -c 16 /dev/random | base64)}
  read -rp "Enter your Elasticsearch password [$ELASTICSEARCH_PASSWORD]: " input
  ELASTICSEARCH_PASSWORD=${input:-$ELASTICSEARCH_PASSWORD}
fi

MOQUI_IMAGE=${MOQUI_IMAGE:-moqui/moquidemo}
read -rp "Enter your moqui image [$MOQUI_IMAGE]: " input
MOQUI_IMAGE=${input:-$MOQUI_IMAGE}

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

# Run ./compose-up compose/default-compose.yml
# if it fails, run ./compose-down.sh compose/default-compose.yml
./compose-up.sh compose/default-compose.yml . eclipse-temurin:11-jdk .env
