#!/usr/bin/env bash
set -euo pipefail

# Run from this directory after editing poc-parameters.env.
. ./poc-parameters.env

load_jks_secret() {
  local secret_name="$1"
  local keystore_file="$2"
  local truststore_file="$3"
  local password_file="$4"
  local jks_password

  for f in "$keystore_file" "$truststore_file" "$password_file"; do
    test -s "$f" || { echo "Missing existing TLS file: $f" >&2; exit 1; }
  done
  grep -q '^jksPassword=' "$password_file" || {
    echo "Expected $password_file to contain jksPassword=<password>" >&2
    exit 1
  }
  jks_password=$(sed -n 's/^jksPassword=//p' "$password_file")
  test -n "$jks_password" || { echo "Empty JKS password in $password_file" >&2; exit 1; }

  # Validate the externally generated PKCS12/JKS files; do not generate or modify them.
  keytool -list -storetype PKCS12 -keystore "$keystore_file" -storepass "$jks_password" >/dev/null
  keytool -list -storetype PKCS12 -keystore "$truststore_file" -storepass "$jks_password" >/dev/null

  # Copy the existing files into the Kubernetes Secret consumed by spec.tls.secretRef.
  oc create secret generic "$secret_name" -n confluent \
    --from-file=keystore.jks="$keystore_file" \
    --from-file=truststore.jks="$truststore_file" \
    --from-file=jksPassword.txt="$password_file" \
    --dry-run=client -o yaml | oc apply -f -
}

load_jks_secret "$KRAFT_TLS_SECRET" "$KRAFT_TLS_KEYSTORE_FILE" "$KRAFT_TLS_TRUSTSTORE_FILE" "$KRAFT_TLS_PASSWORD_FILE"
load_jks_secret "$KAFKA_TLS_SECRET" "$KAFKA_TLS_KEYSTORE_FILE" "$KAFKA_TLS_TRUSTSTORE_FILE" "$KAFKA_TLS_PASSWORD_FILE"
load_jks_secret "$CONNECT_TLS_SECRET" "$CONNECT_TLS_KEYSTORE_FILE" "$CONNECT_TLS_TRUSTSTORE_FILE" "$CONNECT_TLS_PASSWORD_FILE"
load_jks_secret "$SCHEMA_REGISTRY_TLS_SECRET" "$SCHEMA_REGISTRY_TLS_KEYSTORE_FILE" "$SCHEMA_REGISTRY_TLS_TRUSTSTORE_FILE" "$SCHEMA_REGISTRY_TLS_PASSWORD_FILE"
load_jks_secret "$CONTROL_CENTER_TLS_SECRET" "$CONTROL_CENTER_TLS_KEYSTORE_FILE" "$CONTROL_CENTER_TLS_TRUSTSTORE_FILE" "$CONTROL_CENTER_TLS_PASSWORD_FILE"

oc get secret "$KRAFT_TLS_SECRET" "$KAFKA_TLS_SECRET" "$CONNECT_TLS_SECRET" "$SCHEMA_REGISTRY_TLS_SECRET" "$CONTROL_CENTER_TLS_SECRET" -n confluent
