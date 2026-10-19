# ⚠️ SECURITY DEMO — INTENTIONALLY UNSAFE CONTENT

This repository is a **Snyk demonstration project** for showing the whole platform against a
single repo: **Code (SAST), DAST, Open Source (SCA), IaC, Container, and AI (AI-BOM + Agent
Scan).** The base app (AltoroJ / "Patch Mutual") is already a deliberately vulnerable banking
app; this document covers the demo material added on top of it.

**None of this is meant to run in production or be installed into a real agent.** Keep the repo
private or clearly labeled.

## What was added, and why it's safe to scan

| Area | Files | Intentional content |
|---|---|---|
| Open Source (SCA) | `build.gradle` | unused but vulnerable deps (Log4Shell `log4j-core:2.14.1`, jackson-databind, snakeyaml, commons-collections, guava) — declared only, so the build still works |
| IaC | `iac/terraform/main.tf`, `iac/k8s/insecure-deployment.yaml`, existing `k8s-src/privilegedDeployment.yaml` | public S3, open security groups, unencrypted RDS/EBS, privileged/root pods, `latest` tags, hardcoded secrets |
| Container | `containers/Dockerfile.vulnerable` | old base image, runs as root, vulnerable apt/npm packages |
| AI | `ai/`, `.claude/skills/` | AI models + MCP servers/tools + agent skills, including one toxic MCP server and one toxic skill |

### The AI content is inert

- Outbound hosts in the toxic AI files use reserved `.invalid` domains (`attacker.invalid`,
  `repo-helper.invalid`, `telemetry.repo-helper.invalid`) that cannot resolve.
- The toxic `ai/mcp_servers/notes_server.py` `send_webhook` tool only returns a string; it makes
  no network call.
- No real credentials, keys, or personal files are included or accessed.

### The IaC/Container content is never deployed

- The Terraform, K8s, and `Dockerfile.vulnerable` are scanned statically; nothing here provisions
  cloud resources or ships an image unless you deliberately build/apply it.
- Hardcoded passwords (e.g. `Password123!`) are fake demo values.

## Rules

- Do not `terraform apply`, `kubectl apply`, or deploy any manifest here.
- Do not add `ai/.claude/skills/` or `ai/mcp.json` to a real agent/editor config.
- Do not run the `curl | bash` line inside `.claude/skills/repo-helper/SKILL.md`.
- Scanning everything (`snyk test`, `snyk iac test`, `snyk container test`, `snyk aibom`,
  `snyk-agent-scan`) is safe — that's the whole point. See `SNYK-DEMO.md`.
