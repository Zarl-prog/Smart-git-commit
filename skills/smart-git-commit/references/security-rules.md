# Security Rules — Secret Detection & Fix Guide

## 12 Secret Pattern Families

| # | Family | Regex Pattern | Example |
|---|--------|--------------|---------|
| 1 | AWS Access Key ID | `A` + ``KIA[0-9A-Z]{16}` | `A` + ``KIAIOSFODNN7EXAMPLE` |
| 2 | AWS Secret Access Key | `(?i)aws_secret_access_key\s*=\s*\S+` | `aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| 3 | GitHub Tokens | `g` + ``h[pousr]_[A-Za-z0-9]{36}` | `g` + ``hp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| 4 | Stripe Keys | `s` + ``k_(live|test)_[A-Za-z0-9]{24,}` | `s` + ``k_live_xxxxxxxxxxxxxxxxxxxxxxxx` |
| 5 | Generic API Key | `[Aa][Pp][Ii]_?[Kk][Ee][Yy]\s*[:=]\s*\S{16,}` | `API_KEY = sk-xxxxxxxxxxxxxxxx` |
| 6 | Passwords | `[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]\s*[:=]\s*\S{8,}` | `PASSWORD = superSecret123!` |
| 7 | Private Keys | `-----BEGIN (RSA\|EC\|OPENSSH\|DSA\|PGP) PRIVATE KEY-----` | `-----BEGIN RSA PRIVATE KEY-----` |
| 8 | Bearer Tokens | `[Bb]earer\s+[A-Za-z0-9\-_]{20,}` | `Bearer eyJhbGciOiJIUzI1NiIs...` |
| 9 | MongoDB Connection | `mongodb://[^:]+:[^@]+@` | `mongodb://admin:password@cluster0.mongodb.net` |
| 10 | PostgreSQL Connection | `postgresql://[^:]+:[^@]+@` | `postgresql://user:pass@localhost:5432/db` |
| 11 | MySQL Connection | `mysql://[^:]+:[^@]+@` | `mysql://user:pass@localhost:3306/db` |
| 12 | .env / Credential Files | `\.env$`, `\.pem$`, `\.key$`, `credentials` | `.env.production`, `server.key`, `credentials.json` |

---

## What to Do When a Secret Is Found

### If the secret is STAGED but NOT pushed:

```bash
# 1. Unstage the file
git reset HEAD config/credentials.yml

# 2. Replace the secret with an environment variable
# config/credentials.yml → config/credentials.yml.example (committed)
# Actual values go in .env (gitignored)

# 3. Add to .gitignore if needed
echo "config/credentials.yml" >> .gitignore

# 4. Add the safe version
git add config/credentials.yml.example .gitignore

# 5. Commit the fix
git commit -m "chore(config): externalize credentials to env vars"
```

### If the secret was PUSHED (even to a branch):

```bash
# 1. ROTATE the credential immediately
#    - AWS: go to IAM → delete access key → create new one
#    - GitHub: go to Settings → Developer settings → revoke token
#    - Stripe: go to Dashboard → API keys → roll secret key

# 2. Remove from git history using git-filter-repo
#    Install: pip install git-filter-repo  or  brew install git-filter-repo

# 3. Force push the cleaned history
#    git push origin --force --all
```

---

## Scrubbing Secrets from Git History

Use `git-filter-repo` (NOT `git filter-branch` — it's deprecated and slow):

```bash
# Remove a specific file from all of history
git filter-repo --path config/credentials.yml --invert-paths

# Replace a string pattern in all of history
git filter-repo --replace-text <(echo "AKIAI``OSFODNN7EXAMPLE==>REPLACED")

# After cleaning, force push
git push origin --force --all
git push origin --force --tags
```

**⚠️ Warning**: Force pushing rewrites shared history. Coordinate with your team.
Everyone must re-clone after a force push.

---

## False Positive Guidance

These are NOT secrets — they're test fixtures, example values, or placeholders:

| Pattern | When It's Safe | How to Allow |
|---------|---------------|--------------|
| `A` + ``KIA...` | Example AWS key in documentation | Use prefix check — only flag strings with proper format AND length |
| `s` + ``k_test_...` | Stripe test key (starts with s` + ``k_test) | Flag `s` + ``k_live_` only, allow `s` + ``k_test_` |
| `password` in `password_hash` | Not a plaintext password | Skip lines containing `hash`, `bcrypt`, `argon` |
| `Bearer` in `Authorization: Bearer` header | Test client code | Skip test files if context is mock/example |
| `.env.example` | Template file, no real values | Skip files with `.example` suffix |
| `id_rsa.pub` | Public key (suffix is .pub) | Only flag private keys (no .pub suffix) |
| `0xDEADBEEF` | Hex constant, not a secret | Check length: must be 16+ chars for API key pattern |

---

## Environment Variable Best Practices

### Node.js
```bash
# .env (gitignored) — real values
DATABASE_URL=postgresql://user:realpassword@localhost:5432/db
STRIPE_KEY=<your-stripe-secret-key>

# .env.example (committed) — template with placeholders
DATABASE_URL=postgresql://user:password@localhost:5432/db
STRIPE_KEY=<your-stripe-secret-key>

# Access in code
const stripeKey = process.env.STRIPE_KEY;
if (!stripeKey) throw new Error("Missing STRIPE_KEY");
```

### Python
```python
# settings.py
import os
DATABASE_URL = os.environ["DATABASE_URL"]
STRIPE_KEY = os.environ.get("STRIPE_KEY")
```

### Go
```go
// config.go
import "os"
var DatabaseURL = os.Getenv("DATABASE_URL")
var StripeKey = os.Getenv("STRIPE_KEY")
```

### Rust
```rust
// config.rs
use std::env;
let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
let stripe_key = env::var("STRIPE_KEY").expect("STRIPE_KEY must be set");
```

---

## Dangerous File Patterns

Never commit these file types — they almost always contain credentials:

```
*.pem           # SSL/TLS certificates (private keys)
*.key           # SSH private keys
*.p12           # PKCS#12 certificate store
*.keystore      # Java keystore
*.cert          # Certificate files
id_rsa          # SSH private key
id_dsa          # SSH private key (legacy)
.env            # Environment variables
.env.*          # Environment-specific variables
credentials     # Any file named "credentials"
secrets         # Any file named "secrets"
```

Add them to `.gitignore`:
```bash
echo "*.pem" >> .gitignore
echo "*.key" >> .gitignore
echo "credentials" >> .gitignore
```
