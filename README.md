# Agents-Pay-Service

**A free and open-source Loka Agentic Lightning payment and account system for AI multi-Agents, built on LNbits.**

![phase: stable](https://img.shields.io/badge/phase-stable-2EA043) [![license-badge]](LICENSE) ![PRs: welcome](https://img.shields.io/badge/PRs-Welcome-yellow)

> Power your AI agent economy with isolated wallets, a clean HTTP API, and SUI / Lightning payment flows — all in one lightweight Python service.

## What is Agents-Pay-Service?

Agents-Pay-Service is a fork of [LNbits](https://github.com/lnbits/lnbits) customised for the **Loka** agentic ecosystem. It sits between your AI agents and the underlying payment network, giving each agent its own isolated wallet and API key while exposing a unified interface for Lightning (BOLT11) and SUI/Mist payments.

Key adaptations on top of upstream LNbits:

- **SUI / Mist denomination support** — native display formatting, exchange-rate fetching, and invoice creation in SUI units.
- **Multi-agent account isolation** — every agent gets its own wallet and scoped API key; no agent can touch another's funds.
- **Agentic payment extensions** — `orders`, `tpos`, and `lnurlp` extensions pre-installed and tuned for programmatic use.
- **SUI price feeds** — CoinGecko + Binance rate providers for real-time SUI ↔ fiat conversion.

## What agents can do with this service

- **Receive payments:** Generate BOLT11 / LNURL invoices denominated in SUI or fiat.
- **Send payments:** Pay invoices autonomously via the HTTP API.
- **Account isolation:** Each agent wallet has its own API key — compromising one key never exposes the full balance.
- **Extend on demand:** Install LNbits-compatible extensions to add features without touching core code.
- **Integrate anywhere:** Use the REST API to plug payment flows into any LLM framework, orchestration layer, or smart-contract workflow.

## Architecture

```
AI Agent(s)
    │  REST API (per-wallet key)
    ▼
Agents-Pay-Service  (this repo — Python / FastAPI)
    │  funding source abstraction
    ▼
Lightning Node / High-Performance DAG Ledger L2 Payment Backend (e.g. SUI, SETU)
```

## Funding sources

Agents-Pay-Service inherits LNbits' funding-source abstraction. Drop in any backend you already operate:

- **[loka-LND](https://github.com/loka-network/loka-p2p-lnd) — Lightning Network Daemon** _(recommended)_
- Core Lightning, CLNRest
- SparkL2 (SUI Lightning-compatible)
- Boltz, Blink, Alby, Breez, and more

## Getting started

### Prerequisites

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) (recommended) or pip

### Install & run

```bash
git clone https://github.com/your-org/agents-pay-service.git
cd agents-pay-service
uv sync
uv run lnbits --port 5000
# or make dev
```

### Production Deployment (10k+ Agents Scale)

If you are running large-scale multi-agent simulations involving thousands of agents performing concurrent wallet operations, **do not use the default SQLite database**. SQLite uses file-level locking and will crash under high concurrency (`database is locked` errors).

**1. Switch to PostgreSQL:**
Set the database URL in your `.env`:
```env
LNBITS_DATABASE_URL="postgres://user:password@localhost:5432/agents_pay"
```

**2. Start with Uvicorn (Multi-Worker):**
Run the service using `make prod` to utilize Uvicorn's asynchronous capabilities and worker pooling:
```bash
make prod
# Under the hood, this executes:
# uv run uvicorn lnbits.__main__:app --host 0.0.0.0 --port 5000 --workers 8 --limit-concurrency 1000
```

Configure your funding source and denomination in `.env`:

```env
# === Server ===
HOST=127.0.0.1
PORT=5001
LNBITS_DATA_FOLDER="./data"

# === Admin UI ===
LNBITS_ADMIN_UI=true

# === Denomination (SUI ecosystem) ===
LNBITS_DENOMINATION=MIST

# === Funding Source ===
LNBITS_BACKEND_WALLET_CLASS=LndWallet

# LndWallet — Lightning Network Daemon (gRPC)
LND_GRPC_ENDPOINT=127.0.0.1
LND_GRPC_PORT=10009
LND_GRPC_CERT="/path/to/lnd/tls.cert"
LND_GRPC_MACAROON="/path/to/lnd/data/chain/sui/devnet/admin.macaroon"

# === Extensions ===
LNBITS_EXTENSIONS_DEFAULT_INSTALL="tpos"
LNBITS_USER_DEFAULT_EXTENSIONS="lnurlp"

# === Invoice expiry ===
LIGHTNING_INVOICE_EXPIRY=3600
```

Copy `.env.example` (or the `.env` file in this repo) as your starting point, then fill in your node paths. See the [LNbits install guide](https://github.com/lnbits/lnbits/blob/main/docs/guide/installation.md) for the full configuration reference.

## Account & wallet system

Every agent receives an isolated wallet with its own API key. The service ships with transaction history, spending charts, and CSV export out of the box.

<img src="https://i.imgur.com/w8jdGpF.png" style="width:800px">

## Extension system

Non-core features are loaded as extensions, keeping the core lean. Pre-installed extensions:

| Extension | Purpose                             |
| --------- | ----------------------------------- |
| `orders`  | Agent-to-agent order/payment flows  |
| `tpos`    | Point-of-sale for agent services    |
| `lnurlp`  | LNURL-pay endpoint per agent wallet |

<img src="https://i.imgur.com/aEBpwJF.png" style="width:800px">

## HTTP API

Agents interact entirely through the REST API. Full OpenAPI docs are served at `/docs` when the service is running.

<img src="https://i.imgur.com/V742sb9.png" style="width:800px">

## Built on LNbits

Agents-Pay-Service is powered by [LNbits](https://github.com/lnbits/lnbits) — the open-source Lightning toolkit. Upstream improvements and extensions remain compatible.

[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg
