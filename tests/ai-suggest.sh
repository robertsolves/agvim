#!/bin/zsh
# A real Neovim, on a private tmux, asking a fake AI server on this Mac for a suggestion
# as you type. It must arrive with the saved key, show, and go into the file on Tab.
# Its Neovim keeps its state (session files, history) in the test folder.
real_home="$HOME"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export TMUX_TMPDIR=$base; unset TMUX
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $base/guard; cp "${0:A:h:h}/tests/tmux-guard" $base/guard/tmux; export PATH="$base/guard:$PATH" # only this test's own servers, also if its folder goes
mkdir -p $base/p; print -l 'def add(a, b):' '    """Return the sum of a and b."""' > $base/p/demo.py
cat > $base/server.py <<'PY'
import http.server, json, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("content-length", 0)))
        open(sys.argv[2], "a").write(self.headers.get("authorization", "none") + " model=" + json.loads(body).get("model", "?") + "\n")
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.end_headers()
        chunk = {"choices": [{"index": 0, "delta": {"content": "x + b"}}]}
        self.wfile.write(("data: " + json.dumps(chunk) + "\n\ndata: [DONE]\n\n").encode())
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
PY
port=$((20000 + RANDOM % 20000))
python3 -I $base/server.py $port $base/requests & server=$!
sleep 1
print -l 'use=custom' "url_custom=http://127.0.0.1:$port/v1/chat/completions" 'model_custom=test-model' 'key_custom=test-key-123' > $base/ai
tmux -f /dev/null new-session -d -s n -x 110 -y 24 -c $base/p -e XDG_STATE_HOME=$base/state -e AGVIM_AI_FILE=$base/ai "nvim demo.py; sleep 30"
sleep 6
tmux send-keys -t n -l 'Go'; sleep .6; # At a person's pace, stopping just after a keystroke, the hardest case.
for c in r e t u r n ' ' a; do tmux send-keys -t n -l "$c"; sleep .7; done
for i in {1..20}; do sleep 1; tmux capture-pane -p -t n | grep -q 'return ax + b' && break; done
print -r -- "request: $(head -1 $base/requests)"
print -r -- "on screen: $(tmux capture-pane -p -t n | grep -c 'return ax + b')"
tmux send-keys -t n Tab; sleep 1; tmux send-keys -t n Escape; sleep .3; tmux send-keys -t n -l ':w'; tmux send-keys -t n Enter; sleep 1.5
print -r -- "in the file: $(grep -c 'return ax + b' $base/p/demo.py)"
tail -1 $base/p/demo.py
tmux send-keys -t n -l ':qa!'; tmux send-keys -t n Enter; sleep .5
kill $server 2>/dev/null
tmux kill-server 2>/dev/null
