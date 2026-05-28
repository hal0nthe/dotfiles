installed=$(pacman -Qq)

pkg_list=$(paru -Slq | awk -v installed="$installed" '
BEGIN {
  split(installed, arr, "\n")
  for (i in arr) inst[arr[i]] = 1
}
{
  name = $1
  tag = (name in inst) ? "\033[90m[installed]\033[0m" : ""
  printf "%s %s\n", name, tag
}
')

fzf_args=(
  --ansi
  --multi
  --preview 'echo {} | awk "{print \$1}" | xargs -r paru -Sii'
  --preview-window 'down:60%:wrap'
  --preview-label 'ENTER: install | TAB: select | ESC: exit'
  --preview-label-pos 'bottom'
  --color 'marker:green,pointer:green'
)

selected=$(echo "$pkg_list" | fzf "${fzf_args[@]}")

if [[ -n $selected ]]; then
  echo "$selected" \
    | awk '{print $1}' \
    | xargs paru -S --noconfirm
fi
