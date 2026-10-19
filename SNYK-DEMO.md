# Snyk multi-product demo — run guide

One repo, the whole platform. AltoroJ ("Patch Mutual") already demos **Code (SAST)** and
**DAST** well; this guide covers running every product against this single repo, including the
Open Source, IaC, Container, and AI material added for that purpose. See `SECURITY-DEMO.md` for
what's intentional and why it's safe to scan.

> All findings below are deliberate. Keep the repo private or clearly labeled.

## At a glance

| Product | What it scans here | Command |
|---|---|---|
| Code (SAST) | AltoroJ Java/JSP source (`src/`, `WebContent/`) | `snyk code test` |
| DAST | the running AltoroJ web app | Snyk DAST / your DAST runner against the deployed app |
| Open Source (SCA) | `build.gradle` dependencies | `snyk test` |
| IaC | `iac/terraform`, `iac/k8s`, `k8s-src` | `snyk iac test` |
| Container | `containers/Dockerfile.vulnerable` (+ app `Dockerfile`) | `snyk container test <image>` |
| AI-BOM | `ai/` Python (models, datasets, MCP) | `snyk aibom` / `snyk aibom test --enriched` |
| Agent Scan | `.claude/skills`, `ai/mcp.json` | `uvx snyk-agent-scan@latest .claude/skills` |

## 1. Open Source / SCA

```bash
snyk test                      # scans build.gradle
```
Headliner: **Log4Shell** via `org.apache.logging.log4j:log4j-core:2.14.1` (CVE-2021-44228),
plus jackson-databind, snakeyaml, commons-collections (deserialization RCE), and guava. These
are declared but unused, so the app still builds.

## 2. IaC

```bash
snyk iac test                  # scans all .tf / .yaml
```
- `iac/terraform/main.tf` — public-read S3 + public access block disabled, security group open
  `0.0.0.0/0` on 22/3389, unencrypted + publicly accessible RDS with a hardcoded password,
  unencrypted EBS.
- `iac/k8s/insecure-deployment.yaml` — root, privileged, privilege escalation, `latest` tag,
  no resource limits, hardcoded secret in env.
- `k8s-src/privilegedDeployment.yaml` — hostPID, privileged, `CAP_SYS_ADMIN`, docker.sock mount.

## 3. Container

```bash
docker build -t patchmutual-vuln -f containers/Dockerfile.vulnerable containers
snyk container test patchmutual-vuln --file=containers/Dockerfile.vulnerable
```
Old `node:14-buster` base → long OS-package vuln list; runs as root; vulnerable npm packages
(lodash, minimist, axios, jsonwebtoken). The "upgrade base image" advice is a good remediation beat.

## 4. AI — AI-BOM (models + MCP)

```bash
cd ai
pip install -r requirements.txt     # cleanest inventory
snyk aibom                          # inventory (models, datasets, MCP) — CycloneDX
snyk aibom test --enriched          # inventory + Evo policy issues (matches the platform)
```
Surfaces models (`gpt-4o`, `claude-sonnet-4-5`, DistilBERT, MiniLM), datasets, and the MCP chain
(math / notes / weather servers + tools). `aibom` = inventory only; `aibom test` = inventory +
policy evaluation.

## 5. AI — Agent Scan (skills + MCP)

```bash
uvx snyk-agent-scan@latest .claude/skills          # flags the toxic repo-helper skill
uvx snyk-agent-scan@latest ai/mcp.json             # flags the poisoned notes MCP server
```
- `.claude/skills/repo-helper` — hidden credential reads, `curl | bash` + base64 payload, prompt injection.
- `ai/mcp_servers/notes_server.py` — tool poisoning (reads `~/.ssh/id_rsa`) + toxic flow (`read_inbox` → `send_webhook`).

## Suggested demo order

1. **Code** (`snyk code test`) and **DAST** — the established AltoroJ story.
2. **SCA** (`snyk test`) — Log4Shell lands instantly.
3. **IaC** (`snyk iac test`) — cloud + K8s misconfigs.
4. **Container** (`snyk container test`) — base-image vulns.
5. **AI** (`snyk aibom test --enriched`, then `snyk-agent-scan`) — the newest, most differentiated part.

One repo, six-plus products, every finding intentional and explainable.
