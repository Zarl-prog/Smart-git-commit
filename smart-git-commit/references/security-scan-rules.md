# Security Scan Rules

## What to Scan For

### High-Priority Patterns (Block Commit)

| Pattern | Example | Risk |
|---------|---------|------|
| `API_KEY` / `api_key` | `API_KEY=sk-...` | Unauthorized API access |
| `SECRET` / `secret` | `SECRET_KEY=...` | Credential exposure |
| `PASSWORD` / `password` | `password=admin123` | Account compromise |
| `TOKEN` / `token` | `token=ghp_...` | Auth bypass |
| `PRIVATE_KEY` | `-----BEGIN RSA PRIVATE KEY-----` | Crypto key leak |
| `BEARER` | `Authorization: Bearer eyJ...` | Session hijacking |
| `AWS_ACCESS_KEY` / `AWS_SECRET_KEY` | `AKIAIOSFODNN7EXAMPLE` | Cloud resource theft |
| `DATABASE_URL` | `postgresql://user:pass@host/db` | Data breach |
| `CONNECTION_STRING` | `Server=;Database=;User Id=;Password=;` | DB access leak |
| `STRIPE_` / `SK_LIVE_` / `PK_LIVE_` | `sk_live_...` | Payment fraud |
| `GH_TOKEN` / `GITHUB_TOKEN` | `ghp_xxxxxxxxxxxx` | Repo access |

### Medium-Priority Patterns (Warn Only)

| Pattern | Context Needed |
|---------|---------------|
| `.env` file staged | Probably contains secrets |
| `.pem` / `.key` file staged | Private key check needed |
| `credentials` file staged | Credential file check needed |
| `secrets` in filename | Manual review required |
| Hardcoded IPs / URLs | Check for internal infrastructure leak |

## How to Scan

```bash
# Quick scan of staged changes
git diff --cached | grep -inE "(api_key|secret|password|token|private_key|bearer|auth|AKIA)" | head -30

# Check for credential files accidentally staged
git diff --cached --name-only | grep -iE "\.env|\.pem|\.key|credentials|secrets" | head -10

# Full diff scan against secret patterns
git diff --cached | grep -inE "(sk_live_|pk_live_|ghp_|gho_|AKIA|STRIPE)" | head -20
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
- [ ] No AWS keys (`AKIA...`) in any staged file
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
