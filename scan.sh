#! /usr/bin/env sh
set -e

c_flag="false"

escape_sed() {
  echo "$1" | sed -e 's/[&/\]/\\&/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

while getopts 'c' flag; do
  case "${flag}" in
    c) c_flag="true" ;;
    *) break ;;
  esac
done

current_date=$(date +"%y%m%d-%H%M%S")

echo "Running semgrep"

cmd="semgrep"
if [ "$c_flag" = "true" ]; then
  cmd="$cmd ci"
fi
cmd="$cmd scan --output ${current_date}.json --json"
eval "$cmd"
echo "Output file ${current_date}.json created"

cp template.html $current_date.html
echo "Created ${current_date}.html"

formatted_date=$(date +"%d %M %y %H:%M:%S")

jq -c '.results[]' "${current_date}.json" | while read -r result; do
  MESSAGE=$(echo "$result" | jq -r '.extra.message')
  FILE=$(echo "$result" | jq -r '.path')
  CODE=$(echo "$result" | jq -r '.extra.lines')
  VULNERABILITY_CLASS=$(echo "$result" | jq -r '.extra.metadata.vulnerability_class')
  CHECK_ID=$(echo "$result" | jq -r '.check_id')
  SEVERITY=$(echo "$result" | jq -r '.extra.severity')

  LIKELIHOOD=$(echo "$result" | jq -r '.extra.metadata.likelihood')
  IMPACT=$(echo "$result" | jq -r '.extra.metadata.impact')
  CONFIDENCE=$(echo "$result" | jq -r '.extra.metadata.confidence')

  LIKELIHOOD_CLASS="bg-sky-600 text-sky-100"
  IMPACT_CLASS="bg-sky-600 text-sky-100"
  CONFIDENCE_CLASS="bg-sky-600 text-sky-100"

  if [ "$LIKELIHOOD" = "HIGH" ]; then
    LIKELIHOOD_CLASS="bg-red-600 text-red-100"
  fi
  if [ "$IMPACT" = "HIGH" ]; then
    IMPACT_CLASS="bg-red-600 text-red-100"
  fi
  if [ "$CONFIDENCE" = "HIGH" ]; then
    CONFIDENCE_CLASS="bg-red-600 text-red-100"
  fi

  ESCAPED_MESSAGE=$(escape_sed "$MESSAGE")
  ESCAPED_FILE=$(escape_sed "$FILE")
  ESCAPED_CODE_SNIPPET=$(escape_sed "$CODE")
  ESCAPED_VULNERABILITY_CLASS=$(escape_sed "$VULNERABILITY_CLASS")
  ESCAPED_CHECK_ID=$(escape_sed "$CHECK_ID")

  CARD=$(cat card.html)
  CARD=$(echo "$CARD" | sed "s|{MESSAGE}|$ESCAPED_MESSAGE|g")
  CARD=$(echo "$CARD" | sed "s|{FILE}|$ESCAPED_FILE|g")
  CARD=$(echo "$CARD" | sed "s|{CODE}|$ESCAPED_CODE_SNIPPET|g")
  CARD=$(echo "$CARD" | sed "s|{VULNERABILITY_CLASS}|$ESCAPED_VULNERABILITY_CLASS|g")
  CARD=$(echo "$CARD" | sed "s|{CHECK_ID}|$ESCAPED_CHECK_ID|g")
  CARD=$(echo "$CARD" | sed "s|{DATE}|$formatted_date|g")
  CARD=$(echo "$CARD" | sed "s|{IMPACT_CLASS}|$IMPACT_CLASS|g")
  CARD=$(echo "$CARD" | sed "s|{CONFIDENCE_CLASS}|$CONFIDENCE_CLASS|g")
  CARD=$(echo "$CARD" | sed "s|{LIKELIHOOD_CLASS}|$LIKELIHOOD_CLASS|g")
  CARD=$(echo "$CARD" | sed "s|{IMPACT}|$IMPACT|g")
  CARD=$(echo "$CARD" | sed "s|{CONFIDENCE}|$CONFIDENCE|g")
  CARD=$(echo "$CARD" | sed "s|{LIKELIHOOD}|$LIKELIHOOD|g")

  BG_CLASS="bg-gray-100"

  case "${SEVERITY}" in
    ERROR) BG_CLASS="bg-red-100 text-red-900"
      ;;
    WARNING) BG_CLASS="bg-orange-100 text-orange-900"
      ;;
    *) BG_CLASS="bg-gray-100 text-black"
      ;;
  esac

  CARD=$(echo "$CARD" | sed "s|{BG_CLASS}|$BG_CLASS|g")

  ESCAPED_CARD=$(escape_sed "$CARD")
  sed -i "/<div id=\"results\">/a $ESCAPED_CARD" "${current_date}.html"
  sed -i "s|{DATE}|$formatted_date|g" "${current_date}.html"
done

echo "Populated ${current_date}.html"

wkhtmltopdf --enable-local-file-access ${current_date}.html ${current_date}.pdf


echo "Created ${current_date}.pdf"
