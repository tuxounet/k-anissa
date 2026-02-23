"""
Tool "heure" — Retourne la date et l'heure courante.
Micro-service HTTP minimal servant d'exemple de tool.
"""
import json
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        now = datetime.now()
        body = json.dumps({
            "datetime": now.isoformat(),
            "date": now.strftime("%Y-%m-%d"),
            "time": now.strftime("%H:%M:%S"),
            "timezone": "UTC",
        })
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, fmt, *args):
        pass  # silence logs


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 9100), Handler)
    print("Tool 'heure' listening on :9100")
    server.serve_forever()
