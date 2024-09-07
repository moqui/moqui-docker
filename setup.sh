#!/bin/bash

# Set Moqui setup directory
MOQUI_SETUP_DIR="/opt/moqui"

# install git on any linux distro
# Detect the package manager and install Git
if [ -x "$(command -v apt-get)" ]; then
  # Debian-based distributions (e.g., Ubuntu)
  echo "Detected Debian-based distribution. Installing Git..."
  sudo apt-get update -y
  sudo apt-get install git -y
elif [ -x "$(command -v dnf)" ]; then
  # Red Hat-based distributions (e.g., Fedora)
  echo "Detected Red Hat-based distribution. Installing Git..."
  sudo dnf install git -y
elif [ -x "$(command -v yum)" ]; then
  # CentOS or older Red Hat-based distributions
  echo "Detected CentOS/older Red Hat-based distribution. Installing Git..."
  sudo yum install git -y
elif [ -x "$(command -v pacman)" ]; then
  # Arch-based distributions (e.g., Arch Linux, Manjaro)
  echo "Detected Arch-based distribution. Installing Git..."
  sudo pacman -Sy git --noconfirm
elif [ -x "$(command -v zypper)" ]; then
  # SUSE-based distributions (e.g., openSUSE)
  echo "Detected SUSE-based distribution. Installing Git..."
  sudo zypper install -y git
elif [ -x "$(command -v apk)" ]; then
  # Alpine-based distributions
  echo "Detected Alpine-based distribution. Installing Git..."
  sudo apk add git
else
  echo "Unsupported distribution or package manager not detected."
  exit 1
fi

# Verify installation
if git --version >/dev/null 2>&1; then
  echo "Git installation successful. Version: $(git --version)"
else
  echo "Git installation failed."
  exit 1
fi

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
