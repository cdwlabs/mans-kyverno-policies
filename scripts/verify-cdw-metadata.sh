#!/bin/bash
set -euo pipefail

# https://gist.github.com/maxim/6e15aa45ba010ab030c4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
ROOT_DIR="$SCRIPT_DIR/.."
readonly ROOT_DIR
METADATA_FILE="$ROOT_DIR/.cdw/metadata.yaml"
readonly METADATA_FILE

TOKEN=${TOKEN:-"$GITHUB_TOKEN"}
readonly TOKEN
GITHUB_TOKEN=

REPO="cdwlabs/managed-apps-metadata"
readonly REPO
SCHEMA_FILE="cdw-metadata-schema.json"
readonly SCHEMA_FILE
VERSION=${METADATA_VERSION:-"0.0.5"}
readonly VERSION

die() { echo "$*" 1>&2 ; exit 1; }

need() {
  which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

# Authenticate using the gh cli
gh_cli_auth() {
  if ! output=$(gh auth login --with-token <<< "$TOKEN" 2>&1); then
    echo "Error authentication with 'gh auth login': $output" >&2
    return 1
  fi
}

###
# Checking pre-reqs
###
need gh
need check-jsonschema

###
# Login to GitHub
###
gh_cli_auth

TMP_DIR="$(mktemp -d)" || error "failed to create temp directory"
trap 'rm -rf -- "$TMP_DIR"' EXIT

###
# Download schema
###
gh release download "$VERSION" -D "$TMP_DIR" -R "$REPO" -p "$SCHEMA_FILE"

###
# Verify that our required files exist
###
if [ ! -f "$TMP_DIR/$SCHEMA_FILE" ]; then
  die "metadata schema file '$TMP_DIR/$SCHEMA_FILE' does not exist"
fi
if [ ! -f "$METADATA_FILE" ]; then
  die "metadata file '$METADATA_FILE' does not exist"
fi

###
# Finally, perform verifications
###
check-jsonschema --check-metaschema "$TMP_DIR/$SCHEMA_FILE"
check-jsonschema --schemafile "$TMP_DIR/$SCHEMA_FILE" "$METADATA_FILE"
