#!/bin/zsh
# First launch on a clean scratch home, from the built app.
repo="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh AGVIM_INSTALL_ARGS="--no-brew --no-tools" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "${0:A:h:h}/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
mkdir -p $HOME/Desktop $TMUX_TMPDIR $HOME/stubs; unset TMUX; touch ~/.zshrc
export AGVIM_URL=$base/none.git
print -l '#!/bin/zsh' 'print open "$@" >> $HOME/open.log' > ~/stubs/open; chmod +x ~/stubs/open
print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' 'exec -a nvim sleep 1000' > ~/stubs/nvim; chmod +x ~/stubs/nvim
print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' 'exec -a lazygit sleep 1000' > ~/stubs/lazygit; chmod +x ~/stubs/lazygit
export PATH="$HOME/stubs:$PATH"
cp -R $repo/dist/AgVim.app $base/AgVim.app
echo "--- click icon, not installed"; $base/AgVim.app/Contents/MacOS/AgVim; echo rc=$?; cat ~/open.log | sed "s#$HOME#~#"; cat ~/.config/agvim/open.command | sed "s#$base#BASE#"
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
print 'set -g default-terminal xterm-256color' > ~/outer.conf
export PATH="$HOME/stubs:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
o -f ~/outer.conf new-session -d -s o -x 110 -y 30 "zsh ~/.config/agvim/open.command; print EXIT=\$?; sleep 60"; o set -g status off
for i in {1..60}; do sleep 1; o capture-pane -p -t o | grep -qE 'agvim │|EXIT=|isn.t set up' && break; done; echo "first run took ${i}s"; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | cut -c1-100 | head -4
ls -la ~/Desktop | grep AgVim | sed "s#$base#BASE#" | cut -c40-; ls ~/Applications; ls -l ~/.local/bin/agvim | sed "s#$base#BASE#" | cut -c40-; ls ~/.agvim | head -3 | tr '\n' ' '; echo; git -C ~/.agvim status -sb 2>&1 | head -1
b select-window -t '=projects:=agvim'; sleep 1.5; tmux list-windows -t '=agvim' -F '  #{window_name}' 2>/dev/null
echo "--- click icon, running"; : > ~/open.log; print /Applications/Fake.app > ~/.config/agvim/last-terminal; $base/AgVim.app/Contents/MacOS/AgVim; cat ~/open.log
pid=$(b list-clients -F '#{client_pid}'); kill -HUP $pid; sleep 3.5; tmux ls 2>&1 | head -1 | cut -c1-30
echo "--- click icon, closed"; : > ~/open.log; rm ~/.config/agvim/last-terminal; $base/AgVim.app/Contents/MacOS/AgVim; sed "s#$HOME#~#" ~/open.log | cut -c1-140; tail -1 ~/.config/agvim/open.command
echo "--- terminal choice"; print /System/Applications/Utilities/Terminal.app > ~/.config/agvim/terminal; : > ~/open.log; ~/.agvim/lib/terminal ~/.config/agvim/open.command; sed "s#$HOME#~#" ~/open.log | cut -c1-120
o kill-server 2>/dev/null; b kill-server 2>/dev/null; tmux kill-server 2>/dev/null
echo "--- uninstall"; (~/.agvim/uninstall.sh --yes 2>&1 | grep -E 'Desktop|app' | cut -c1-70); ls ~/Desktop ~/Applications | tr '\n' ' '; echo
