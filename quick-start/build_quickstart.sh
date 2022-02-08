#!/bin/bash

OS="$(uname)"
if [[ "$OS" == "Darwin" ]]; then
  ON_MACOS=1
fi

CONFIG="./variables"
TEMPLATE="./templates/"
DESTINATION="./dist"
SCRIPT_DESTINATION="$DESTINATION"

mkdir -p "$DESTINATION"
cp -r "$TEMPLATE" "$SCRIPT_DESTINATION"

while read -r line; do
  setting="$( echo "$line" | cut -d '=' -f 1 )"
  value="$( echo "$line" | cut -d '=' -f 2- )"

  if [[ -n "${ON_MACOS-}" ]]; then
      find "$SCRIPT_DESTINATION" -type f -name "*.tpl" | xargs sed -i "" "s;%${setting}%;${value};g"
  else
      find "$SCRIPT_DESTINATION" -type f -name "*.tpl" | xargs sed -i -e "s;%${setting}%;${value};g"
  fi
done < "$CONFIG"

for f in $(find "$SCRIPT_DESTINATION" -type f -name '*.tpl')
do
  mv "$f" "$(echo $f | sed -n 's;^\(.*\).tpl;\1;p')"
done

cd "$SCRIPT_DESTINATION" || exit 1
tar -czvf release.tar.gz resources


