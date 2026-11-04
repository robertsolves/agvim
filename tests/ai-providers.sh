#!/bin/zsh
# Every kind of AI source, through a real Neovim: a fake server on this Mac answers in
# that service's own format and checks how it sends the key. The suggestion must show,
# and Tab must put it in the file. Real endpoints are checked with agentnv ai test.
real_home="$HOME"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export TMUX_TMPDIR=$base; unset TMUX
cat > $base/server.py <<'PY'
import http.server, json, socketserver, sys
TEXT = "x + b"
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("content-length", 0))) or b"{}")
        h = self.headers
        if h.get("x-api-key"):
            kind, key = "claude", h["x-api-key"]
            data = {"type": "content_block_delta", "delta": {"type": "text_delta", "text": TEXT}}
        elif h.get("x-goog-api-key"):
            kind, key = "gemini", h["x-goog-api-key"]
            data = {"candidates": [{"content": {"parts": [{"text": TEXT}]}}]}
        elif "prompt" in body and "/fim/" not in self.path:
            kind, key = "fim", h.get("authorization", "")
            data = {"choices": [{"index": 0, "text": TEXT}]}
        else:
            kind, key = "chat", h.get("authorization", "")
            data = {"choices": [{"index": 0, "delta": {"content": TEXT}}]}
        open(sys.argv[2], "a").write(f"{kind} {key} {self.path}\n")
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.end_headers()
        self.wfile.write(("data: " + json.dumps(data) + "\n\n").encode())
        if kind != "gemini":
            self.wfile.write(b"data: [DONE]\n\n")
    def log_message(self, *a): pass
class S(socketserver.ThreadingMixIn, http.server.HTTPServer): daemon_threads = True
S(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
PY
port=$((20000 + RANDOM % 20000))
python3 -I $base/server.py $port $base/requests & server=$!
sleep 1
try() {
  local id="$1" url="$2" expect="$3" d="$base/$1"
  mkdir -p $d; print -l 'def add(a, b):' '    """Return the sum of a and b."""' > $d/demo.py
  : > $base/requests
  print -l "use=$id" "url_$id=http://127.0.0.1:$port$url" "model_$id=test-model" "key_$id=key-$id" > $d/ai
  tmux -f /dev/null new-session -d -s "$id" -x 110 -y 24 -c $d -e AGENTNV_AI_FILE=$d/ai "nvim demo.py; sleep 20"
  sleep 5
  tmux send-keys -t "$id" -l 'Go'; sleep .5
  for c in r e t u r n ' ' a; do tmux send-keys -t "$id" -l "$c"; sleep .5; done
  local shown=0
  for i in {1..12}; do sleep 1; tmux capture-pane -p -t "$id" | grep -q 'return ax + b' && { shown=1; break; }; done
  tmux send-keys -t "$id" Tab; sleep .8; tmux send-keys -t "$id" Escape; sleep .3; tmux send-keys -t "$id" -l ':w'; tmux send-keys -t "$id" Enter; sleep 1
  local filed=$(grep -c 'return ax + b' $d/demo.py)
  local sent=$(grep -cE "^$expect" $base/requests)
  [ "$sent" -gt 0 ] && sent=1
  print -r -- "$id key-sent=$sent shown=$shown in-file=$filed ($(head -1 $base/requests | cut -d' ' -f1,3-))"
  tmux send-keys -t "$id" -l ':qa!'; tmux send-keys -t "$id" Enter; sleep .3
  tmux kill-session -t "=$id" 2>/dev/null
}
try claude /v1/messages 'claude key-claude '
try openai /v1/chat/completions 'chat Bearer key-openai '
try gemini /v1beta/models 'gemini key-gemini '
try deepseek /beta/completions 'fim Bearer key-deepseek '
try mistral /v1/fim/completions 'chat Bearer key-mistral '
try groq /openai/v1/chat/completions 'chat Bearer key-groq '
kill $server 2>/dev/null
tmux kill-server 2>/dev/null
