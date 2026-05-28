#!/usr/bin/env bash

installed=$(pacman -Qq)

pkg_list=$(pacman -Sl | awk -v installed="$installed" '
BEGIN {
  split(installed, arr, "\n")
  for (i in arr) inst[arr[i]] = 1
}
{
  name = $2
  tag = (name in inst) ? "\033[90m[installed]\033[0m" : ""
  printf "%s %s\n", name, tag
}
')

fzf_args=(
  --ansi
  --multi
  --preview 'echo {} | awk "{print \$1}" | xargs -r pacman -Sii'
  --preview-window 'down:60%:wrap'
  --color 'pointer:green,marker:green'
  --preview-label 'ENTER: install | TAB: select | ESC: exit'
  --preview-label-pos 'bottom'
)

selected=$(echo "$pkg_list" | fzf "${fzf_args[@]}")

if [[ -n $selected ]]; then

  echo "$selected" \
    | awk '{print $1}' \
    | xargs sudo pacman -S --noconfirm

fi
