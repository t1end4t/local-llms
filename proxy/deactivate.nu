# proxy/deactivate.nu — restore Claude Code to Anthropic API
# Usage: source proxy/deactivate.nu

$env.ANTHROPIC_BASE_URL = ""
$env.ANTHROPIC_API_KEY = ""

print "[proxy] Claude Code → Anthropic API (restored)"
