#!/usr/bin/env bash
#
# scan-secrets.sh — Scan staged changes for secrets, keys, and credentials
#
# Usage: bash scripts/scan-secrets.sh
# Exit code: 0 = clean, 1 = secrets found (blocks commit)
#
# Scans for:
#   - API keys, tokens, passwords, private keys
#   - .env, .pem, .key, credentials files accidentally staged
#   - AWS keys, database connection strings, payment provider keys

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUSPICIOUS_FOUND=0

# Patterns to scan in diff content
HIGH_PRIORITY_PATTERNS=(
  "api[_-]?key[[:space:]]*=[[:space:]]*['\"]?[A-Za-z0-9_-]{10,}"  # API key assignments
  "secret[_-]?key[[:space:]]*=[[:space:]]*['\"][A-Za-z0-9_-]{10,}" # Secret key assignments
  "secret[[:space:]]*=[[:space:]]*['\"][A-Za-z0-9_-]{10,}"        # Secret assignments
  "password[[:space:]]*=[[:space:]]*['\"][A-Za-z0-9!@#$%^&*()_+-=]{6,}"  # Password assignments
  "private[_-]?key"
  "BEGIN[[:space:]]+(RSA|DSA|EC|OPENSSH|PGP)[[:space:]]+PRIVATE[[:space:]]+KEY"
  "bearer[[:space:]]+[A-Za-z0-9._-]{20,}"  # Bearer tokens (long strings only)
  "AKIA[0-9A-Z]{16}"        # AWS Access Key
  "sk_live_"                  # Stripe live secret key
  "pk_live_"                  # Stripe live publishable key
  "ghp_"                      # GitHub personal access token
  "gho_"                      # GitHub OAuth token
  "ghu_"                      # GitHub user token
  "DATABASE_URL[[:space:]]*="
  "CONNECTION_STRING[[:space:]]*="
  "REDIS_URL[[:space:]]*="
  "MONGODB_URI[[:space:]]*="
  "postgresql://[^:]+:[^@]+@"  # postgres://user:pass@
  "mysql://[^:]+:[^@]+@"      # mysql://user:pass@
  "mongodb://[^:]+:[^@]+@"    # mongodb://user:pass@
  "redis://:[^@]+@"           # redis://:pass@
)

# File patterns that should never be staged
DANGEROUS_FILES=(
  "\.env$"
  "\.env\."
  "\.pem$"
  "\.key$"
  "credentials"
  "secrets"
  "\.keystore"
  "id_rsa"
  "id_dsa"
  "\.cert$"
  "\.p12$"
)

echo "=========================================="
echo "  Smart Git Commit — Security Scan"
echo "=========================================="
echo ""

# ------------------------------------------------------------------
# 1. Check if there's anything staged
# ------------------------------------------------------------------
if ! git diff --cached --quiet 2>/dev/null; then
  STAGED_FILES=$(git diff --cached --name-only)
  echo "📂 Scanning staged changes in $(echo "$STAGED_FILES" | wc -l) file(s)..."
  echo ""
else
  echo "ℹ️  No staged changes to scan."
  echo "   (Run 'git add <file>' first, then scan again.)"
  echo ""
  exit 0
fi

# ------------------------------------------------------------------
# 2. Scan diff content for high-priority patterns
# ------------------------------------------------------------------
echo "--- Scanning diff content for secrets ---"
echo ""

for pattern in "${HIGH_PRIORITY_PATTERNS[@]}"; do
  RESULTS=$(git diff --cached | grep -inE "$pattern" 2>/dev/null | head -5 || true)
  if [ -n "$RESULTS" ]; then
    echo -e "${RED}⚠  Suspicious pattern found: ${pattern}${NC}"
    while IFS= read -r line; do
      echo "   $line"
    done <<< "$RESULTS"
    echo ""
    SUSPICIOUS_FOUND=1
  fi
done

# ------------------------------------------------------------------
# 3. Check for dangerous file types in staged files
# ------------------------------------------------------------------
echo "--- Checking staged files for credential file types ---"
echo ""

for file_pattern in "${DANGEROUS_FILES[@]}"; do
  MATCHES=$(git diff --cached --name-only | grep -iE "$file_pattern" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    echo -e "${RED}⚠  Dangerous file type staged: ${file_pattern}${NC}"
    while IFS= read -r file; do
      echo "   - $file"
    done <<< "$MATCHES"
    echo ""
    SUSPICIOUS_FOUND=1
  fi
done

# ------------------------------------------------------------------
# 4. Check for files larger than 1MB (potential credential dumps)
# ------------------------------------------------------------------
echo "--- Checking for unusually large staged files ---"
echo ""

git diff --cached --name-only 2>/dev/null | while IFS= read -r file; do
  if [ -f "$file" ]; then
    SIZE=$(wc -c < "$file" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 1048576 ]; then
      echo -e "${YELLOW}⚠  Large file staged: $file ($(( SIZE / 1024 )) KB)${NC}"
    fi
  fi
done

# ------------------------------------------------------------------
# 5. Summary
# ------------------------------------------------------------------
echo "=========================================="
if [ "$SUSPICIOUS_FOUND" -eq 1 ]; then
  echo -e "${RED}🔴 SECURITY SCAN FAILED — Secrets detected${NC}"
  echo "   Review the findings above before committing."
  echo "   Run: git reset HEAD <file> to unstage."
  echo "=========================================="
  exit 1
else
  echo -e "${GREEN}✅ Security scan passed — no secrets found${NC}"
  echo "=========================================="
  exit 0
fi
