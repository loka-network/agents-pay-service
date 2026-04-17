# Changelog

## Unreleased
- Optimized `make prod` background logging in `Makefile`: application logs naturally rotate in `data/logs/` (via loguru), while terminal stdout is discarded (`/dev/null`) and stderr crash logs are output to `uvicorn_error.log` to prevent unbounded log growth.
- Fixed postgres healthcheck in `tests/docker-compose.yaml` to specify correct db name and username to avoid `role "root" does not exist` error.
- Added `scripts/patch_extensions_sui.sh` — idempotent patch script for SUI-adapting extensions (tpos, lnurlp, orders) after install/upgrade.
- Adapted TPoS extension: replaced hardcoded 'sats' with dynamic denomination, fixed currency labels, receipt text, and formatAmount calls.
- Adapted LNURLp extension: fixed default currency label and form submission for SUI base unit.
- Adapted Orders extension: notification messages now use dynamic denomination instead of hardcoded 'sats'.
- Fixed admin `/payments` page: amount and fee columns now properly convert MIST→SUI via `formatBalance()` instead of displaying raw MIST with "sui" label.
- Fixed admin `/payments` page: LNbits balance chart header now shows value in SUI (divided by 1e9) with correct unit label instead of "sats".
- Fixed BOLT11 decoder to handle invoices without amount multiplier suffix (whole coin amounts from LND-SUI).
- Fixed `calculate_fiat_amounts` to treat SUI/MIST as native base units, preventing erroneous fiat exchange rate lookups.
- Whitelisted SUI/MIST in `CreateInvoice` Pydantic validator to allow invoice creation with native SUI units.
- Fixed fiat tracking initialization on page refresh for SUI nodes (was blocked by `isSatsDenomination` check).
- Fixed receive dialog unit dropdown visibility for SUI denomination (corrected `denomination` → `g.denomination` reference).
- Allowed decimal input (e.g. 0.5 SUI) in receive dialog by excluding SUI from integer-only validation.
- Adapted exchange rate calculations to support Sui (MIST) dynamically based on the node's `/v1/getinfo` chain response.
- Switched base unit exchange precision from 10^8 (Satoshis) to 10^9 (MIST) when Sui is detected as the underling main chain.
- Exchanged `BTC` fiat price queries with `SUI` queries for underlying fiat price providers.
