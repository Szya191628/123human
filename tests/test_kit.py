from pathlib import Path
import ast
import subprocess
import unittest
import zipfile
import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parent.parent

class KitTests(unittest.TestCase):
    def test_python_compiles(self):
        for p in (ROOT / 'scripts').glob('*.py'):
            ast.parse(p.read_text(encoding='utf-8'), filename=str(p))

    def test_shell_syntax(self):
        for p in (ROOT / 'scripts').glob('*.sh'):
            r = subprocess.run(['bash', '-n', str(p)], capture_output=True, text=True)
            self.assertEqual(0, r.returncode, f'{p}: {r.stderr}')

    def test_required_files(self):
        required = [
            'README.md', 'config/settings.env.example', 'scripts/install.sh',
            'scripts/start-livetalking.sh', 'scripts/start-livestream.sh',
            'scripts/doctor.py', 'scripts/test-session.py', 'scripts/start-all.sh',
            'scripts/stop-all.sh', 'scripts/logs.sh', 'scripts/status.sh',
            'examples/直播话术示例.txt', 'windows/打开部署终端.bat',
        ]
        for rel in required:
            self.assertTrue((ROOT / rel).is_file(), rel)

    def test_doctor_help(self):
        r = subprocess.run(['python3', str(ROOT/'scripts/doctor.py'), '--help'], capture_output=True, text=True)
        self.assertEqual(0, r.returncode, r.stderr)

    def test_session_http_integration_mock(self):
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"code": 0, "data": {"sessions": [{"sessionid": "test123"}]}}).encode())
            def do_POST(self):
                assert self.path == "/human"
                length = int(self.headers.get("Content-Length", "0"))
                data = json.loads(self.rfile.read(length))
                assert data["sessionid"] == "test123"
                assert data["type"] == "echo"
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"code": 0, "msg": "ok"}')
            def log_message(self, *args):
                pass
        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            base = f"http://127.0.0.1:{server.server_address[1]}"
            target = str(ROOT / "scripts/test-session.py")
            for arguments in (["--list"], ["--send", "--sessionid", "test123", "--text", "你好"]):
                r = subprocess.run(['python3', target, '--base-url', base, *arguments], capture_output=True, text=True, timeout=10)
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertIn('"code": 0', r.stdout)
        finally:
            server.shutdown()
            server.server_close()

    def test_session_requires_sessionid(self):
        r = subprocess.run(['python3', str(ROOT/'scripts/test-session.py'), '--send'], capture_output=True, text=True)
        self.assertNotEqual(0, r.returncode)
        self.assertIn('--sessionid', r.stderr)

if __name__ == '__main__':
    unittest.main()

# Optional integration of the local HTTP API client against a fake LiveTalking server.
# No GPU, external connection or model is needed for this test.
