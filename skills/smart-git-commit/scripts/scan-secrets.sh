#!/usr/bin/env bash
#
# scan-secrets.sh — Scan staged changes for secrets, keys, and credentials
#
# Usage: bash scripts/scan-secrets.sh
# Exit code: 0 = clean, 1 = secrets found (blocks commit)
# Stdout: JSON {status, findings[]}
# Stderr: Human-readable progress and color output

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUSPICIOUS_FOUND=0
FINDINGS_JSON="[]"
FINDINGS_ARR=()

# High-priority patterns (block commit)
HIGH_PRIORITY_PATTERNS=(
  "api[_-]?key[[:space:]]*=[[:space:]]*['\\\"]?[A-Za-z0-9_-]{10,}"
  "secret[_-]?key[[:space:]]*=[[:space:]]*['\\\"][A-Za-z0-9_-]{10,}"
  "secret[[:space:]]*=[[:space:]]*['\\\"][A-Za-z0-9_-]{10,}"
  "password[[:space:]]*=[[:space:]]*['\\\"][A-Za-z0-9!@#$%^&*()_+-=]{6,}"
  "BEGIN[[:space:]]+(RSA|DSA|EC|OPENSSH|PGP)[[:space:]]+PRIVATE[[:space:]]+KEY"
  "bearer[[:space:]]+[A-Za-z0-9._-]{20,}"
  "A""KIA[0-9A-Z]{16}"
  "s""k_live_"
  "p""k_live_"
  "ghp_[A-Za-z0-9]{36}"
  "gho_[A-Za-z0-9]{36}"
  "DATABASE_URL[[:space:]]*="
  "CONNECTION_STRING[[:space:]]*="
  "REDIS_URL[[:space:]]*="
  "MONGODB_URI[[:space:]]*="
  "postgresql://[^:]+:[^@]+@"
  "mysql://[^:]+:[^@]+@"
  "mongodb://[^:]+:[^@]+@"
  "redis://:[^@]+@"
)

# Dangerous file patterns
DANGEROUS_FILES=(
  "\\.env$"
  "\\.env\\."
  "\\.pem$"
  "\\.key$"
  "credentials"
  "secrets"
  "\\.keystore"
  "id_rsa"
  "id_dsa"
  "\\.cert$"
  "\\.p12$"
)

add_finding() {
  local severity="$1"
  local message="$2"
  local file="$3"
  local line="${4:-}"
  FINDINGS_ARR+=("$(printf '%s' "{\"severity\":\"$severity\",\"message\":\"$message\",\"file\":\"$file\",\"line\":\"$line\"}")")
}

echo -e "${YELLOW}Smart Git Commit — Security Scan${NC}" >&2
echo "" >&2

# Check for staged changes
if ! git diff --cached --quiet 2>/dev/null; then
  STAGED_FILES=$(git diff --cached --name-only)
  echo -e "Scanning staged changes ($(echo "$STAGED_FILES" | wc -l) file(s))..." >&2
else
  echo -e "${YELLOW}No staged changes to scan.${NC}" >&2
  echo '{"status":"pass","findings":[],"message":"No staged changes to scan"}' >&2
  exit 0
fi

# Scan diff content for high-priority patterns
for pattern in "${HIGH_PRIORITY_PATTERNS[@]}"; do
  RESULTS=$(git diff --cached | grep -inE "$pattern" 2>/dev/null | head -5 || true)
  if [ -n "$RESULTS" ]; then
    SUSPICIOUS_FOUND=1
    while IFS= read -r line; do
      file_line=$(echo "$line" | cut -d: -f1,2)
      snippet=$(echo "$line" | cut -d: -f3- | sed 's/^[[:space:]]*//' | head -c 80)
      add_finding "high" "Secret pattern matched: $snippet" "staged diff" "$file_line"
      echo -e "${RED}⚠  Secret found at $file_line${NC}" >&2
    done <<< "$RESULTS"
  fi
done

# Check for dangerous file types
for file_pattern in "${DANGEROUS_FILES[@]}"; do
  MATCHES=$(git diff --cached --name-only | grep -iE "$file_pattern" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    SUSPICIOUS_FOUND=1
    while IFS= read -r file; do
      add_finding "high" "Dangerous file type staged" "$file" ""
      echo -e "${RED}⚠  Dangerous file staged: $file${NC}" >&2
    done <<< "$MATCHES"
  fi
done

# Check for large files (potential credential dumps)
git diff --cached --name-only 2>/dev/null | while IFS= read -r file; do
  if [ -f "$file" ]; then
    SIZE=$(wc -c < "$file" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 1048576 ]; then
      add_finding "medium" "Large file staged ($(( SIZE / 1024 )) KB)" "$file" ""
      echo -e "${YELLOW}⚠  Large file: $file ($(( SIZE / 1024 )) KB)${NC}" >&2
    fi
  fi
done

# Build JSON output
JSON_FINDINGS="["
FIRST=true
for f in "${FINDINGS_ARR[@]}"; do
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    JSON_FINDINGS+=","
  fi
  JSON_FINDINGS+="$f"
done
JSON_FINDINGS+="]"

if [ "$SUSPICIOUS_FOUND" -eq 1 ]; then
  echo -e "${RED}SECURITY SCAN FAILED — Secrets detected${NC}" >&2
  echo "{\"status\":\"fail\",\"findings\":$JSON_FINDINGS,\"message\":\"Secrets detected — commit blocked\"}"
  exit 1
else
  echo -e "${GREEN}Security scan passed — no secrets found${NC}" >&2
  echo "{\"status\":\"pass\",\"findings\":[],\"message\":\"No secrets found\"}"
  exit 0
fi
