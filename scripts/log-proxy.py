#!/usr/bin/env python3
"""
Logging proxy — prints incoming LLM messages to stdout, forwards to llama-server.

Usage:
    python3 scripts/log-proxy.py [--listen-port 8081] [--target-port 8080]

Then point Claude Code at the listen port:
    ANTHROPIC_BASE_URL=http://127.0.0.1:8081 claude --model local
"""

import argparse
import http.server
import json
import urllib.error
import urllib.request

LISTEN_PORT = 8081
TARGET_PORT = 8080


class LoggingProxy(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n)

        try:
            data = json.loads(body)
            messages = data.get("messages", [])
            print(f"\n{'='*60}")
            print(f"  {len(messages)} message(s)  |  model: {data.get('model','?')}  |  max_tokens: {data.get('max_tokens','?')}")
            print(f"{'='*60}")
            for m in messages:
                role = m.get("role", "?")
                content = m.get("content", "")
                if isinstance(content, list):
                    content = "\n".join(
                        p.get("text", "") for p in content if isinstance(p, dict) and "text" in p
                    )
                print(f"\n--- {role} ---")
                print(content)
            print(f"\n{'='*60}\n", flush=True)
        except Exception as e:
            print(f"[log-proxy] parse error: {e}", flush=True)

        target = f"http://127.0.0.1:{self.server.target_port}{self.path}"  # type: ignore[attr-defined]
        req = urllib.request.Request(target, body, dict(self.headers))
        try:
            resp = urllib.request.urlopen(req)
            self.send_response(resp.status)
            for k, v in resp.headers.items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        pass  # suppress access log noise


class ProxyServer(http.server.HTTPServer):
    def __init__(self, listen_port, target_port):
        self.target_port = target_port
        super().__init__(("127.0.0.1", listen_port), LoggingProxy)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="LLM request logging proxy")
    parser.add_argument("--listen-port", type=int, default=LISTEN_PORT)
    parser.add_argument("--target-port", type=int, default=TARGET_PORT)
    args = parser.parse_args()

    print(f"Logging proxy: 127.0.0.1:{args.listen_port} → 127.0.0.1:{args.target_port}")
    print("Set ANTHROPIC_BASE_URL=http://127.0.0.1:{args.listen_port} to use\n")

    server = ProxyServer(args.listen_port, args.target_port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
