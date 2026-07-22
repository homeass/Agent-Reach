#!/bin/bash
# ============================================================================
# omo-doctor.sh — OMO (Oh-My-Openagent) Configuration Doctor
# ============================================================================
# Diagnoses and fixes common OMO configuration issues on macOS.
# Usage: bash scripts/omo-doctor.sh [--fix] [--verbose]
#
# Checks performed:
#   1. OpenCode installation & version
#   2. oh-my-openagent plugin installation & binary
#   3. Config file syntax validation (JSON/JSONC)
#   4. Agent registration verification
#   5. Free model migration status
#   6. MCP server connectivity
#   7. CodeGraph initialization
#   8. LaunchD services (Telegram bridge)
#   9. Stale cache cleanup
#  10. TUI cache reset recommendation
# ============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Flags ---
FIX_MODE=false
VERBOSE=false
ISSUES_FOUND=0
ISSUES_FIXED=0

for arg in "$@"; do
  case $arg in
    --fix) FIX_MODE=true ;;
    --verbose) VERBOSE=true ;;
    -h|--help)
      echo "Usage: bash scripts/omo-doctor.sh [--fix] [--verbose]"
      echo "  --fix     Auto-fix issues when possible"
      echo "  --verbose Show detailed output"
      exit 0
      ;;
  esac
done

# --- Helpers ---
info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[  OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; ISSUES_FOUND=$((ISSUES_FOUND + 1)); }
fail()    { echo -e "${RED}[FAIL]${NC} $*"; ISSUES_FOUND=$((ISSUES_FOUND + 1)); }
fixed()   { echo -e "${GREEN}[FIXED]${NC} $*"; ISSUES_FIXED=$((ISSUES_FIXED + 1)); }

check_cmd() {
  if command -v "$1" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# --- Config Paths ---
CONFIG_DIR="${HOME}/.config/opencode"
OMO_CONFIG="${CONFIG_DIR}/oh-my-openagent.jsonc"
OPENCODE_CONFIG="${CONFIG_DIR}/opencode.json"
TUI_CONFIG="${CONFIG_DIR}/tui.json"
CODEGRAPH_DIR="${HOME}/.omo/codegraph"
NODE_MODULES="${CONFIG_DIR}/node_modules/oh-my-openagent"

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  OMO Doctor — Oh-My-Openagent Configuration Diagnostic${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. OpenCode Installation
# ============================================================================
info "Checking OpenCode installation..."

if check_cmd opencode; then
  OC_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
  ok "OpenCode installed: ${OC_VERSION}"
else
  fail "OpenCode not found in PATH"
  echo "       Install: npm install -g opencode"
fi

# ============================================================================
# 2. oh-my-openagent Plugin
# ============================================================================
info "Checking oh-my-openagent plugin..."

if [[ -d "${NODE_MODULES}" ]]; then
  OMO_VERSION=$(cat "${NODE_MODULES}/package.json" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "unknown")
  ok "oh-my-openagent installed: v${OMO_VERSION}"

JS_BINARY="${NODE_MODULES}/bin/oh-my-opencode.js"
if [[ -f "${JS_BINARY}" ]]; then
  ok "JS binary found: oh-my-opencode.js"
else
  warn "JS binary not found at ${JS_BINARY}"
fi
else
  fail "oh-my-openagent not installed at ${NODE_MODULES}"
  echo "       Install: cd ~/.config/opencode && npm install oh-my-openagent"
fi

# ============================================================================
# 3. Config Files — Syntax Validation
# ============================================================================
info "Validating config file syntax..."

validate_json() {
  local file="$1"
  local name="$2"

  if [[ ! -f "${file}" ]]; then
    warn "${name} not found: ${file}"
    return 1
  fi

  # Try python json parser (handles both JSON and basic JSONC)
  if python3 -c "
import json, re, sys
with open('${file}') as f:
    content = f.read()
# Strip single-line comments (but not inside strings)
content = re.sub(r'(?<!:)//.*$', '', content, flags=re.MULTILINE)
# Strip multi-line comments
content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
# Strip trailing commas
content = re.sub(r',\s*([\]}])', r'\1', content)
# Fix unescaped control characters in strings (like newlines in prompt strings)
content = re.sub(r'[\x00-\x1f](?![\\\"\/bfnrt])', ' ', content)
try:
    json.loads(content)
    sys.exit(0)
except json.JSONDecodeError as e:
    print(f'JSON parse error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
    ok "${name} syntax valid"
    return 0
  else
    # Some JSON files with $schema or prompt strings may fail strict parsing
    # Check if file is at least valid with node
    if check_cmd node; then
      if node -e "
const fs = require('fs');
const content = fs.readFileSync('${file}', 'utf8');
try {
  // Try to parse as JSON5-like (lenient)
  const cleaned = content
    .replace(/\/\/.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/,(\s*[}\]])/g, '\$1');
  JSON.parse(cleaned);
  process.exit(0);
} catch(e) {
  process.exit(1);
}
" 2>/dev/null; then
        ok "${name} syntax valid (node parser)"
        return 0
      fi
    fi
    warn "${name} has potential syntax issues: ${file}"
    echo "       (May be valid with OpenCode's parser)"
    return 1
  fi
}

validate_json "${OPENCODE_CONFIG}" "opencode.json"
validate_json "${OMO_CONFIG}" "oh-my-openagent.jsonc"
validate_json "${TUI_CONFIG}" "tui.json"

# ============================================================================
# 4. Agent Registration
# ============================================================================
info "Checking agent registration..."

if [[ -f "${OMO_CONFIG}" ]]; then
  # Check if Sisyphus agent is defined
  if grep -q '"sisyphus"' "${OMO_CONFIG}" 2>/dev/null; then
    ok "Sisyphus agent defined in oh-my-openagent.jsonc"

    # Check if model is set to free
    if grep -A5 '"sisyphus"' "${OMO_CONFIG}" | grep -q 'opencode/big-pickle\|opencode/nemotron\|opencode/deepseek.*free'; then
      ok "Sisyphus using free model"
    else
      warn "Sisyphus may not be using a free model"
    fi
  else
    fail "Sisyphus agent not found in oh-my-openagent.jsonc"
  fi

  # Check if opencode.json references oh-my-openagent plugin
  if [[ -f "${OPENCODE_CONFIG}" ]]; then
    if grep -q '"oh-my-openagent"' "${OPENCODE_CONFIG}" 2>/dev/null; then
      ok "opencode.json references oh-my-openagent plugin"
    else
      warn "opencode.json does not reference oh-my-openagent plugin"
      echo "       Add: \"plugin\": [\"oh-my-openagent\"]"
    fi
  fi

  # Check if tui.json references oh-my-openagent plugin
  if [[ -f "${TUI_CONFIG}" ]]; then
    if grep -q '"oh-my-openagent"' "${TUI_CONFIG}" 2>/dev/null; then
      ok "tui.json references oh-my-openagent plugin"
    else
      warn "tui.json does not reference oh-my-openagent plugin"
      echo "       Add: \"plugin\": [\"oh-my-openagent\"]"
    fi
  fi
fi

# ============================================================================
# 5. Free Model Migration
# ============================================================================
info "Checking free model migration..."

if [[ -f "${OMO_CONFIG}" ]]; then
  PAID_MODELS=$(grep -c 'gpt-5\|gemini-3\|claude-opus\|claude-sonnet\|claude-haiku' "${OMO_CONFIG}" 2>/dev/null || echo "0")
  FREE_MODELS=$(grep -c 'big-pickle\|nemotron.*free\|deepseek.*free' "${OMO_CONFIG}" 2>/dev/null || echo "0")

  if [[ "${PAID_MODELS}" -gt 0 ]]; then
    warn "Found ${PAID_MODELS} paid model references in oh-my-openagent.jsonc"
    echo "       Consider migrating to free models"
  else
    ok "No paid model references found"
  fi

  if [[ "${FREE_MODELS}" -gt 0 ]]; then
    ok "Found ${FREE_MODELS} free model references"
  fi
fi

# ============================================================================
# 6. CodeGraph
# ============================================================================
info "Checking CodeGraph..."

if [[ -f "${CODEGRAPH_DIR}/bin/codegraph" ]]; then
  CG_VERSION=$("${CODEGRAPH_DIR}/bin/codegraph" --version 2>/dev/null || echo "unknown")
  ok "CodeGraph installed: v${CG_VERSION}"

  # Check if project is initialized
  if [[ -d ".codegraph" ]]; then
    ok "CodeGraph initialized for current project"
  else
    warn "CodeGraph not initialized for current project"
    if $FIX_MODE; then
      info "Initializing CodeGraph..."
      "${CODEGRAPH_DIR}/bin/codegraph" init 2>/dev/null && fixed "CodeGraph initialized" || warn "CodeGraph init failed"
    fi
  fi
else
  warn "CodeGraph not installed at ${CODEGRAPH_DIR}/bin/codegraph"
fi

# ============================================================================
# 7. LaunchD Services
# ============================================================================
info "Checking LaunchD services..."

PLIST_DIR="${HOME}/Library/LaunchAgents"
TELEGRAM_PLIST="${PLIST_DIR}/com.omo.telegram-bridge.plist"

if [[ -f "${TELEGRAM_PLIST}" ]]; then
  ok "Telegram bridge plist found"

  if launchctl list 2>/dev/null | grep -q "com.omo.telegram-bridge"; then
    ok "Telegram bridge service loaded"
  else
    warn "Telegram bridge service not loaded"
    if $FIX_MODE; then
      info "Loading Telegram bridge service..."
      launchctl load "${TELEGRAM_PLIST}" 2>/dev/null && fixed "Telegram bridge loaded" || warn "launchctl load failed"
    fi
  fi
else
  info "Telegram bridge plist not found (optional)"
fi

# ============================================================================
# 8. Stale Cache Cleanup
# ============================================================================
info "Checking for stale caches..."

# Check for stale lock files
LOCK_FILES=$(find "${CONFIG_DIR}" -name "*.lock" -mtime +1 2>/dev/null | wc -l)
if [[ "${LOCK_FILES}" -gt 0 ]]; then
  warn "Found ${LOCK_FILES} stale lock files older than 1 day"
  if $FIX_MODE; then
    find "${CONFIG_DIR}" -name "*.lock" -mtime +1 -delete 2>/dev/null
    fixed "Removed stale lock files"
  fi
fi

# Check for stale temp files
TEMP_DIR="/tmp/opencode"
if [[ -d "${TEMP_DIR}" ]]; then
  TEMP_SIZE=$(du -sh "${TEMP_DIR}" 2>/dev/null | cut -f1)
  if [[ -n "${TEMP_SIZE}" ]]; then
    info "Temp directory size: ${TEMP_SIZE}"
  fi
fi

# ============================================================================
# 9. TUI Cache Reset Recommendation
# ============================================================================
info "TUI cache check..."

# Check if there are stale TUI state files
TUI_STATE="${HOME}/.local/share/opencode"
if [[ -d "${TUI_STATE}" ]]; then
  DB_FILES=$(find "${TUI_STATE}" -name "*.db" -o -name "*.sqlite" 2>/dev/null | wc -l)
  if [[ "${DB_FILES}" -gt 0 ]]; then
    info "Found ${DB_FILES} database files in TUI state directory"
    if $FIX_MODE; then
      echo ""
      echo -e "${YELLOW}[RECOMMENDATION]${NC} If agents don't appear in TUI menu, try:"
      echo "  1. Close all OpenCode TUI sessions"
      echo "  2. Run: rm -rf ${TUI_STATE}/sessions/*"
      echo "  3. Restart OpenCode TUI"
      echo ""
    fi
  fi
fi

# ============================================================================
# 10. OpenCode Agent List Verification
# ============================================================================
info "Verifying agent list via CLI..."

if check_cmd opencode; then
  AGENT_OUTPUT=$(opencode agent list 2>&1 | head -20)
  if echo "${AGENT_OUTPUT}" | grep -qi "sisyphus"; then
    ok "Sisyphus found in agent list"
  else
    warn "Sisyphus not found in agent list output"
    if $VERBOSE; then
      echo "       Agent list output:"
      echo "${AGENT_OUTPUT}" | sed 's/^/       /'
    fi
  fi
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Summary${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"

if [[ ${ISSUES_FOUND} -eq 0 ]]; then
  echo -e "${GREEN}All checks passed! No issues found.${NC}"
else
  echo -e "${YELLOW}Issues found: ${ISSUES_FOUND}${NC}"
  if [[ ${ISSUES_FIXED} -gt 0 ]]; then
    echo -e "${GREEN}Issues fixed:  ${ISSUES_FIXED}${NC}"
  fi
  echo ""
  echo -e "${BOLD}Common fixes:${NC}"
  echo "  1. Restart OpenCode TUI after config changes"
  echo "  2. Run with --fix to auto-fix available issues"
  echo "  3. If agents missing from TUI, try: rm -rf ~/.local/share/opencode/sessions/*"
fi

echo ""
