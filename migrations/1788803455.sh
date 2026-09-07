echo "Add center-left and center-right bar sections"

# The bar now supports five layout sections
# (left, center-left, center, center-right, right). Existing shell.json files
# only have three, which the shell tolerates by treating missing sections as
# empty — but materialize the new arrays so CLI tooling and settings deltas
# see a consistent shape. Never touch sections the user already has.

config_file="$HOME/.config/omarchy/shell.json"

if [[ -s $config_file ]]; then
  tmp=$(mktemp)
  jq '
    if (.bar.layout? | type) == "object" then
      .bar.layout["center-left"] |= (if type == "array" then . else [] end)
      | .bar.layout["center-right"] |= (if type == "array" then . else [] end)
    else . end
  ' "$config_file" >"$tmp" && mv "$tmp" "$config_file" || rm -f "$tmp"
fi
