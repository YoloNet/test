# VPN Autoscript — Full Project Discovery & Reverse-Engineering Plan

You are working on an existing VPN autoscript project.

The project is already functional and contains Xray-core integration, including both official and custom Xray-core components.

## CRITICAL RULE

DO NOT MODIFY, DELETE, MOVE, RENAME, overwrite, or generate production project files during this phase.

This phase is DISCOVERY ONLY.

Your first responsibility is to completely understand the existing project before making any changes.

Do not assume how anything works. Inspect the actual source code and configuration.

---

## 1. Complete Project Inventory

Recursively inspect the entire project.

Identify:

- Shell scripts
- Bash scripts
- Python
- JavaScript
- TypeScript
- Go
- JSON
- YAML/YML
- TOML
- Configuration files
- Systemd services
- Cron jobs
- Docker files
- Makefiles
- Xray configuration
- Xray source code
- Custom Xray-core source
- Official Xray-core components
- Embedded binaries
- Libraries
- Installation scripts
- Uninstallation scripts
- Update scripts
- Backup scripts
- User-management scripts
- Telegram-related code
- Web/API components
- Database/storage files

Create a complete file inventory.

For each important file explain:

- Purpose
- Dependencies
- Functions
- Inputs
- Outputs
- Files modified
- Commands executed
- External services contacted
- Whether it is safe to modify
- Whether it is generated automatically

---

## 2. Determine the Architecture

Trace the complete execution flow.

Determine:

- How installation works
- How Xray is installed
- How Xray is configured
- How Xray is started
- How Xray is stopped
- How Xray is restarted
- How users are created
- How users are deleted
- How users are edited
- How UUIDs are generated
- How UUIDs are stored
- How expiry dates are stored
- How expired users are handled
- How online users are detected
- How configuration changes are applied
- How Xray configuration is validated
- How Xray is reloaded
- How logs are generated
- How errors are handled
- How backups work
- How updates work

Produce a clear architecture diagram in Markdown.

---

## 3. Xray-Core Audit

Identify every Xray-related component.

Determine:

- Official Xray-core version
- Custom Xray-core version
- Source repositories if available
- Custom modifications
- Why the custom version exists
- Which files were modified
- Which protocols are supported
- Which transports are supported
- Which ports are used
- Which WebSocket paths are used
- TLS configuration
- REALITY configuration if present
- gRPC configuration if present
- fallback configuration
- reverse proxy configuration
- Cloudflare integration if present
- Caddy/Nginx integration if present

Do not modify Xray yet.

Document exactly how the existing system interacts with Xray.

---

## 4. User Management Audit

Find every implementation related to VPN users.

Document:

### Add user

- Input parameters
- Username/name handling
- UUID handling
- Expiry handling
- Protocol selection
- Configuration modification
- Database/storage modification
- Xray reload procedure

### Edit user

Determine whether the current project supports:

- Name change
- UUID change
- Expiry change
- Protocol change
- Status change

Document exactly how each works.

### Delete user

Document:

- How the user is identified
- How the Xray configuration is changed
- How storage is changed
- How Xray is reloaded
- Whether historical data is retained

### Renew user

Document existing behavior.

### Expired users

Document:

- Detection
- Automatic expiration
- Deletion
- Disable behavior
- Cron/systemd timer usage

### Online users

Document exactly how online users are detected.

---

## 5. IP Restriction Audit

Find every mechanism that restricts script usage based on IP address.

Search for:

- IP whitelist
- IP blacklist
- server IP validation
- license IP
- installation IP
- VPS IP binding
- allowed IP
- remote IP validation
- API IP restrictions
- domain/IP binding
- Telegram IP restrictions
- hardcoded IP addresses
- external IP checking services

Do NOT remove anything yet.

Create:

docs/IP_RESTRICTIONS.md

with:

- File
- Function
- Line/reference
- What the restriction does
- Why it exists
- Dependencies
- Recommended removal strategy

---

## 6. Encoded / Obfuscated Code Audit

Find all encoded, compressed, encrypted, or obfuscated source code.

Check for:

- Base64
- gzip
- xz
- hex encoding
- eval
- dynamically generated shell
- compressed payloads
- encrypted strings
- encoded scripts
- generated source
- hidden commands

For every affected file:

- Identify the encoding/obfuscation method
- Determine the original content where possible
- Determine what the code actually does
- Determine whether the code is required
- Determine whether it can safely be converted to readable source

DO NOT overwrite the original files.

Create:

docs/OBFUSCATED_FILES.md

---

## 7. Dependencies

Identify:

- OS requirements
- Packages
- Runtime requirements
- Python modules
- Node packages
- Go requirements
- External binaries
- External APIs
- Domains
- DNS requirements
- Cloudflare dependencies
- Telegram dependencies
- Database dependencies

Create:

docs/DEPENDENCIES.md

---

## 8. Security Audit

Inspect the project for:

- Hardcoded passwords
- API tokens
- Telegram bot tokens
- SSH credentials
- Private keys
- Secrets
- Unsafe permissions
- Command injection risks
- Shell injection
- Unsafe temporary files
- Insecure file permissions
- Unsafe user input
- Arbitrary command execution
- Privilege escalation risks

DO NOT publish or expose discovered secrets in documentation.

Redact secrets.

---

## 9. Create User Lifecycle Documentation

Document the complete lifecycle:

CREATE
  ↓
ACTIVE
  ↓
RENEW / EDIT
  ↓
EXPIRY
  ↓
EXPIRED
  ↓
DISABLED / REMOVED

Explain every transition.

---

## 10. Produce Final Discovery Report

After inspecting everything, create:

docs/
├── ARCHITECTURE.md
├── FILE_INVENTORY.md
├── USER_MANAGEMENT.md
├── XRAY.md
├── IP_RESTRICTIONS.md
├── OBFUSCATED_FILES.md
├── DEPENDENCIES.md
├── SECURITY.md
├── USER_LIFECYCLE.md
└── DISCOVERY_REPORT.md

DISCOVERY_REPORT.md must include:

1. What the project does
2. How it works
3. Important components
4. User-management architecture
5. Xray architecture
6. Existing Telegram functionality
7. Existing API functionality
8. IP restrictions
9. Obfuscated code
10. Security issues
11. Technical debt
12. Duplicate code
13. Dangerous code
14. Recommended refactoring
15. Recommended new architecture
16. Potential breaking changes
17. Migration requirements
18. Items that require human approval before modification

---

## 11. DO NOT IMPLEMENT THE NEW FEATURES YET

Do NOT yet implement:

- Telegram bot redesign
- Admin role
- Reseller role
- Buyer role
- Pricing system
- New database
- New API
- IP restriction removal
- Decoding replacement
- User-management rewrite

First finish discovery and documentation.

When complete, provide a concise summary of:

- Files inspected
- Architecture discovered
- Existing user-management functions
- Xray implementation
- IP restrictions discovered
- Encoded/obfuscated files discovered
- Security concerns
- Recommended architecture for the next phase
- Any uncertainties that require human confirmation

Wait for further instructions before modifying the project.