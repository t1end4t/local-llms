# proxy/activate.nu — redirect Claude Code to local llama-server
# Usage: source proxy/activate.nu

$env.ANTHROPIC_BASE_URL = "http://127.0.0.1:8080"
$env.ANTHROPIC_API_KEY = "sk-no-key-required"

print "[local] Claude Code → llama-server (http://127.0.0.1:8080)"
print "[local] Deactivate with: source proxy/deactivate.nu"
