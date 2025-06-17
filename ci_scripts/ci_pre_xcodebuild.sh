#!/bin/bash
set -e

mkdir -p "$PROJECT_DIR/Configs"

echo "$SecretPlist" | base64 --decode > "$PROJECT_DIR/Configs/Secret.plist"
echo "$StoreKitConfig" | base64 --decode > "$PROJECT_DIR/Configs/BubblePlus.storekit"
echo "$StoreKitCertificate"     | base64 --decode > "$PROJECT_DIR/Configs/StoreKitTestCertificate.cer"
