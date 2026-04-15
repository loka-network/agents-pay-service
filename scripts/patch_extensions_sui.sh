#!/usr/bin/env bash
# =============================================================================
# SUI Denomination Patch for LNbits Extensions
# =============================================================================
# This script patches installed LNbits extensions (tpos, lnurlp, orders) to
# support SUI/MIST denominations. Extensions are installed from external repos
# and ignored by .gitignore, so changes are lost on upgrade.
#
# Run this script after installing or upgrading extensions:
#   bash scripts/patch_extensions_sui.sh
#
# It is idempotent — safe to run multiple times.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EXT_DIR="$ROOT_DIR/lnbits/extensions"

MARKER="__SUI_PATCHED__"

patch_file() {
    local file="$1"
    shift
    if [ ! -f "$file" ]; then
        echo "  SKIP (not found): $file"
        return
    fi
    if grep -q "$MARKER" "$file" 2>/dev/null; then
        echo "  SKIP (already patched): $file"
        return
    fi
    echo "  PATCHING: $file"
    # Apply all sed replacements passed as arguments
    for cmd in "$@"; do
        sed -i '' "$cmd" "$file"
    done
    # Add marker at end of file
    echo "" >> "$file"
    echo "// $MARKER" >> "$file"
}

patch_py_file() {
    local file="$1"
    shift
    if [ ! -f "$file" ]; then
        echo "  SKIP (not found): $file"
        return
    fi
    if grep -q "$MARKER" "$file" 2>/dev/null; then
        echo "  SKIP (already patched): $file"
        return
    fi
    echo "  PATCHING: $file"
    for cmd in "$@"; do
        sed -i '' "$cmd" "$file"
    done
    echo "" >> "$file"
    echo "# $MARKER" >> "$file"
}

echo "=== SUI Extension Patch ==="
echo ""

# ---------------------------------------------------------------------------
# 1. TPoS - index.js
# ---------------------------------------------------------------------------
echo "[1/5] TPoS index.js"
TPOS_INDEX="$EXT_DIR/tpos/static/js/index.js"
if [ -f "$TPOS_INDEX" ] && ! grep -q "$MARKER" "$TPOS_INDEX" 2>/dev/null; then
    echo "  PATCHING: $TPOS_INDEX"

    # Prepend the helper functions at the top of the file
    HELPER_BLOCK="const _tposBaseUnit = (typeof SETTINGS !== 'undefined' \&\& ['mist', 'sui'].includes(String(SETTINGS.denomination).toLowerCase())) ? String(SETTINGS.denomination).toLowerCase() : 'sats'
const _tposIsBaseUnit = (c) => {
  const lc = (c || '').toLowerCase()
  return lc === 'sats' || lc === 'sat' || lc === 'mist' || lc === 'sui'
}
"
    # Use a temp file approach for prepending
    TMP_FILE=$(mktemp)
    echo "$HELPER_BLOCK" > "$TMP_FILE"
    cat "$TPOS_INDEX" >> "$TMP_FILE"
    mv "$TMP_FILE" "$TPOS_INDEX"

    # Replace sats checks
    sed -i '' "s/code === 'SAT' || code === 'SATS'/_tposIsBaseUnit(code)/g" "$TPOS_INDEX"
    sed -i '' "s/(currency || '').toLowerCase() === 'sats'/_tposIsBaseUnit(currency)/g" "$TPOS_INDEX"
    sed -i '' "s/this\.formDialog\.data\.currency !== 'sats'/\!_tposIsBaseUnit(this.formDialog.data.currency)/g" "$TPOS_INDEX"
    sed -i '' "s/data\.currency === 'sats'/_tposIsBaseUnit(data.currency)/g" "$TPOS_INDEX"
    sed -i '' "s/if (currency == 'sats') {/if (_tposIsBaseUnit(currency)) {/g" "$TPOS_INDEX"
    sed -i '' "s/return LNbits\.utils\.formatSat(price) + ' sat'/return LNbits.utils.formatBalance(price, currency)/g" "$TPOS_INDEX"
    sed -i '' "s/return LNbits\.utils\.formatSat(amount) + ' sat'/return LNbits.utils.formatBalance(amount, currency)/g" "$TPOS_INDEX"
    sed -i '' "s/this\.currencyOptions = \['sats'/this.currencyOptions = [_tposBaseUnit/g" "$TPOS_INDEX"

    echo "// $MARKER" >> "$TPOS_INDEX"
else
    echo "  SKIP: $TPOS_INDEX"
fi

# ---------------------------------------------------------------------------
# 2. TPoS - tpos.js
# ---------------------------------------------------------------------------
echo "[2/5] TPoS tpos.js"
TPOS_MAIN="$EXT_DIR/tpos/static/js/tpos.js"
if [ -f "$TPOS_MAIN" ] && ! grep -q "$MARKER" "$TPOS_MAIN" 2>/dev/null; then
    echo "  PATCHING: $TPOS_MAIN"

    HELPER_BLOCK="const _tposIsBaseUnit = (c) => {
  const lc = (c || '').toLowerCase()
  return lc === 'sats' || lc === 'sat' || lc === 'mist' || lc === 'sui'
}
"
    TMP_FILE=$(mktemp)
    echo "$HELPER_BLOCK" > "$TMP_FILE"
    cat "$TPOS_MAIN" >> "$TMP_FILE"
    mv "$TMP_FILE" "$TPOS_MAIN"

    sed -i '' "s/code === 'SAT' || code === 'SATS'/_tposIsBaseUnit(code)/g" "$TPOS_MAIN"
    sed -i '' "s/(currency || '').toLowerCase() === 'sats'/_tposIsBaseUnit(currency)/g" "$TPOS_MAIN"
    sed -i '' "s/tpos\.currency == 'sats'/_tposIsBaseUnit(tpos.currency)/g" "$TPOS_MAIN"
    sed -i '' "s/this\.currency === 'sats'/_tposIsBaseUnit(this.currency)/g" "$TPOS_MAIN"
    sed -i '' "s/currency == 'sats'/_tposIsBaseUnit(currency)/g" "$TPOS_MAIN"
    sed -i '' "s/return LNbits\.utils\.formatSat(amount) + ' sats'/return LNbits.utils.formatBalance(amount, currency)/g" "$TPOS_MAIN"
    sed -i '' "s/LNbits\.utils\.getCurrencySymbol('BTC')/LNbits.utils.getCurrencySymbol(typeof SETTINGS !== 'undefined' \&\& ['mist', 'sui'].includes(String(SETTINGS.denomination).toLowerCase()) ? 'SUI' : 'BTC')/g" "$TPOS_MAIN"

    echo "// $MARKER" >> "$TPOS_MAIN"
else
    echo "  SKIP: $TPOS_MAIN"
fi

# ---------------------------------------------------------------------------
# 3. TPoS - receipt.js
# ---------------------------------------------------------------------------
echo "[3/5] TPoS receipt.js"
TPOS_RECEIPT="$EXT_DIR/tpos/static/components/receipt.js"
if [ -f "$TPOS_RECEIPT" ] && ! grep -q "$MARKER" "$TPOS_RECEIPT" 2>/dev/null; then
    echo "  PATCHING: $TPOS_RECEIPT"

    sed -i '' "s|Rate (sat/|Rate (' + ((typeof SETTINGS !== 'undefined' \&\& ['mist','sui'].includes(String(SETTINGS.denomination).toLowerCase())) ? 'mist' : 'sat') + '/|g" "$TPOS_RECEIPT"
    sed -i '' "s/currency != 'sats'/\!_tposIsBaseUnit(currency)/g" "$TPOS_RECEIPT"
    sed -i '' "s/Total (sats)/Total (' + ((typeof SETTINGS !== 'undefined' \&\& ['mist','sui'].includes(String(SETTINGS.denomination).toLowerCase())) ? 'mist' : 'sats') + ')/g" "$TPOS_RECEIPT"

    echo "// $MARKER" >> "$TPOS_RECEIPT"
else
    echo "  SKIP: $TPOS_RECEIPT"
fi

# ---------------------------------------------------------------------------
# 4. LNURLp - index.js
# ---------------------------------------------------------------------------
echo "[4/5] LNURLp index.js"
LNURLP_INDEX="$EXT_DIR/lnurlp/static/index.js"
if [ -f "$LNURLP_INDEX" ] && ! grep -q "$MARKER" "$LNURLP_INDEX" 2>/dev/null; then
    echo "  PATCHING: $LNURLP_INDEX"

    # Replace the default currency label
    sed -i '' "s/format: val => val ?? 'sat'/format: val => val ?? (typeof SETTINGS !== 'undefined' \&\& ['mist', 'sui'].includes(String(SETTINGS.denomination).toLowerCase()) ? SETTINGS.denomination : 'sat')/g" "$LNURLP_INDEX"
    sed -i '' "s/(link\.currency || 'sat')/(link.currency || (typeof SETTINGS !== 'undefined' \&\& ['mist', 'sui'].includes(String(SETTINGS.denomination).toLowerCase()) ? SETTINGS.denomination : 'sat'))/g" "$LNURLP_INDEX"
    sed -i '' "s/data\.currency === 'satoshis'/data.currency === 'satoshis' || data.currency === 'mist'/g" "$LNURLP_INDEX"

    echo "// $MARKER" >> "$LNURLP_INDEX"
else
    echo "  SKIP: $LNURLP_INDEX"
fi

# ---------------------------------------------------------------------------
# 5. Orders - services.py
# ---------------------------------------------------------------------------
echo "[5/5] Orders services.py"
ORDERS_SVC="$EXT_DIR/orders/services.py"
if [ -f "$ORDERS_SVC" ] && ! grep -q "$MARKER" "$ORDERS_SVC" 2>/dev/null; then
    echo "  PATCHING: $ORDERS_SVC"

    sed -i '' 's/{amount_sat} sats/{amount_sat} {denomination}/g' "$ORDERS_SVC"
    # Insert denomination variable before the message line
    sed -i '' '/amount_sat = order.amount_msat/a\
    denomination = getattr(settings, "lnbits_denomination", None) or "sats"' "$ORDERS_SVC"

    echo "" >> "$ORDERS_SVC"
    echo "# $MARKER" >> "$ORDERS_SVC"
else
    echo "  SKIP: $ORDERS_SVC"
fi

# ---------------------------------------------------------------------------
# 6. Splitpayments (No patch required)
# ---------------------------------------------------------------------------
# The splitpayments extension calculates amounts purely based on percentages
# and does not hardcode 'sat' or 'BTC' strings in its frontend UI.
# Backend math uses 'amount_msat' which safely maps to mmist in our SUI fork.
# Hence, no sed patching is needed for this extension.

echo ""
echo "=== Patch complete ==="
echo "Restart LNbits server to apply changes."
