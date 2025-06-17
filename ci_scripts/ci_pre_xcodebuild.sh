#!/bin/bash
#set -euo pipefail

echo "🔧 Preparing confidential files for build..."

mkdir -p "$CI_PRIMARY_REPOSITORY_PATH/Bubble/Store"

# Check and decode SecretPlist
if [[ -z "${SecretPlist:-}" ]]; then
  echo "❌ Missing SecretPlist environment variable"
  exit 1
fi
echo "$SecretPlist" | base64 -d > "$CI_PRIMARY_REPOSITORY_PATH/Bubble/Secret.plist"

# Check and decode StoreKitConfig
if [[ -z "${StoreKitConfig:-}" ]]; then
  echo "❌ Missing StoreKitConfig environment variable"
  exit 1
fi
echo "$StoreKitConfig" | base64 -d > "$CI_PRIMARY_REPOSITORY_PATH/Bubble/Store/BubblePlus.storekit"

# Check and decode StoreKitCertificate
if [[ -z "${StoreKitCertificate:-}" ]]; then
  echo "❌ Missing StoreKitCertificate environment variable"
  exit 1
fi
echo "$StoreKitCertificate" | base64 -d > "$CI_PRIMARY_REPOSITORY_PATH/Bubble/Store/StoreKitTestCertificate.cer"

echo "✅ All secret files restored to $CI_PRIMARY_REPOSITORY_PATH/Bubble"
