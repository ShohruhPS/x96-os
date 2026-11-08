# X96 OS shell defaults
case "$-" in *i*) ;; *) return 0 2>/dev/null ;; esac
if [ -n "${BASH_VERSION:-}" ]; then
  if [ "$(id -u)" = 0 ]; then u='\[\e[1;38;5;203m\]\u'; else u='\[\e[1;38;5;171m\]\u'; fi
  PS1="${u}\[\e[0;38;5;245m\]@\[\e[1;38;5;213m\]\h \[\e[0;38;5;111m\]\w\[\e[0m\] \$ "
fi
alias ll='ls -lh --color=auto' la='ls -lAh --color=auto' l='ls --color=auto'
alias grep='grep --color=auto' df='df -h' free='free -h'
alias update='x96os update'
