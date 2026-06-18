import http.server
import socketserver
import sys
import signal

PORT = 8080

class MyServer(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write("Hello, World! Python HTTP Server is running.\n".encode("utf-8"))

def signal_handler(sig, frame):
    print("\nNhận tín hiệu kết thúc, đóng server...", flush=True)
    sys.exit(0)

# Đăng ký xử lý tín hiệu SIGTERM và SIGINT để đảm bảo tắt an toàn (graceful shutdown)
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

print(f"Khởi động HTTP server trên port {PORT}...", flush=True)
try:
    with socketserver.TCPServer(("", PORT), MyServer) as httpd:
        httpd.serve_forever()
except Exception as e:
    print(f"Lỗi khởi động server: {e}", file=sys.stderr)
    sys.exit(1)
