from flask import Flask, request
import os
import socket

app = Flask(__name__)

def shutdown_server():
    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        raise RuntimeError('Not running with the Werkzeug Server')
    func()

@app.route("/")
def hello():
    html = "<h3>Hello {name}!</h3> <b>Hostname:</b> {hostname}<br/>"
    return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname())

@app.route("/die")
def die():
    shutdown_server()

@app.route("/mem")
def mem():
    #Let's eat up all memory
    [f for f in range(1024**1024)]

@app.route("/health")
def health():
    return "ok"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=4000)
