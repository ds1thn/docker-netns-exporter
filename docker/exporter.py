from http.server import BaseHTTPRequestHandler, HTTPServer

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain; version=0.0.4')
            self.end_headers()
            with open('/app/metrics/metrics.prom', 'r') as f:
                metrics = f.read()
            self.wfile.write(metrics.encode('utf-8'))

def run(server_class=HTTPServer, handler_class=MetricsHandler, port=80):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()

if __name__ == "__main__":
    run()
