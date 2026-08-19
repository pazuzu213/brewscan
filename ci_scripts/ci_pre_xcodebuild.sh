#!/bin/bash
set -e

# Inject secrets from Xcode Cloud environment into Info.plist at build time.
# Runs automatically before xcodebuild. No secrets are committed to source.

OPENAI_KEY="${OPENAI_API_KEY:-}"
AUTH_URL="${AUTH_BASE_URL:-https://cultures-makeup-conf-rank.trycloudflare.com}"
WORKSPACE="${CI_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
PLIST="${WORKSPACE}/BrewScan/Info.plist"

if [ -z "$OPENAI_KEY" ]; then
    echo "WARNING: OPENAI_API_KEY not set in Xcode Cloud env; key will be empty"
fi

/usr/libexec/PlistBuddy -c "Set :OpenAIAPIKey ${OPENAI_KEY}" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :OpenAIAPIKey string ${OPENAI_KEY}" "$PLIST"

/usr/libexec/PlistBuddy -c "Set :AuthBaseURL ${AUTH_URL}" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :AuthBaseURL string ${AUTH_URL}" "$PLIST"

echo "Info.plist written with CI configuration"
