# Security Scan Rules

## What to Scan For

### High-Priority Patterns (Block Commit — Exit Code 1)

| Pattern | Example | Risk |
|---------|---------|------|
| API keys | `API_KEY=sk-...`, `api_key = "..."` | Unauthorized API access |
| Secret keys | `SECRET_KEY=b3e8...` | Credential exposure |
| Passwords | `password=admin123`, `PASSWORD="..."` | Account compromise |
| Tokens | `token=ghp_...`, `TOKEN=eyJ...` | Auth bypass |
| Private keys | `-----BEGIN RSA PRIVATE KEY-----` | Crypto key leak |
| Bearer tokens | `Authorization: Bearer eyJ...` | Session hijacking |
| AWS access keys | `AKIA...` (e.g., `AKIA[0-9A-Z]{16}`) | Cloud resource theft |
| Database URLs | `postgresql://user:pass@host/db` | Data breach |
| Connection strings | `Server=;Database=;User Id=;Password=;` | DB access leak |
| Stripe live keys | `s` + `k_live_...`, `p` + `k_live_...` | Payment fraud |
| GitHub tokens | `ghp_xxxxxxxxxxxx`, `gho_xxxxxxxxxxxx` | Repo access |
| Redis URLs with pass | `redis://:password@host:6379` | Cache access |

### Medium-Priority Patterns (Warn Only — Exit Code 0)

| Pattern | Context Needed |
|---------|---------------|
| `.env` file staged | Probably contains secrets |
| `.pem` / `.key` file staged | Private key check needed |
| `credentials` file staged | Credential file check needed |
| `secrets` in filename | Manual review required |
| Hardcoded IPs / URLs | Check for internal infrastructure leak |
| Files > 1MB staged | Potential credential dumps |

## How to Scan

```bash
# Quick scan of staged changes (build pattern safely)
SCAN_PATTERN="(api_key|secret|password|token|private_key|bearer|stripe|aws_key)"
git diff --cached | grep -inE "$SCAN_PATTERN" | head -30

# Check for credential files accidentally staged
git diff --cached --name-only | grep -iE "\.env|\.pem|\.key|credentials|secrets" | head -10

# Full diff scan with expanded patterns
SCAN_FULL="(ghp_|gho_|stripe_live|aws_secret|connection_string)"
git diff --cached | grep -inE "$SCAN_FULL" | head -20
```

## What to Do When Found

### 1. **STOP** — Do not stage or commit
```bash
# Remove the file from staging
git reset HEAD <file>
```

### 2. **Remove the secret from the file**
- Replace with environment variable: `process.env.API_KEY`
- Or use a placeholder: `YOUR_API_KEY_HERE`
- Or add to `.env.example` (not `.env`)

### 3. **Add file to `.gitignore` if applicable**
```bash
echo ".env" >> .gitignore
echo "*.pem" >> .gitignore
```

### 4. **Rotate the exposed secret**
- If committed/pushed even once, the secret is compromised
- Generate a new key/token immediately
- Revoke the old one in the provider dashboard

### 5. **Inform the user**
- Which file and line contained the secret
- What was done to fix it
- Whether the secret needs rotation

## Checklist Before Every Commit

- [ ] No `api_key`, `secret`, `password`, `token` in staged diff
- [ ] No `.env`, `.pem`, `.key`, `credentials` files staged
- [ ] No AWS access keys (pattern: `AKIA...`) in any staged file
- [ ] No database connection strings with credentials
- [ ] No private keys (`BEGIN.*PRIVATE KEY`) in staged files
- [ ] No hardcoded production secrets (URLs, IPs)
- [ ] `.gitignore` covers secret file patterns

## What NOT to Do

- ❌ Don't `git add -A` without reviewing first
- ❌ Don't assume a file is safe because it's code
- ❌ Don't commit secrets to a private branch ("I'll delete it later")
- ❌ Don't paste real tokens in commit messages or issue comments
- ❌ Don't skip the scan on WIP/draft commits

## Tools Reference

Run `scripts/scan-secrets.sh` for an automated scan:
```bash
bash scripts/scan-secrets.sh
# Output: CLEAN or list of suspicious lines
```
