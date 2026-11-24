#!/bin/bash
# Usage: bash check_m3u.sh android.m3u
# Tests every stream in the playlist and writes:
#   working.m3u  - only the channels that answered with a valid playlist/stream
#   report.txt   - OK / DEAD line for every channel
IN="$1"; OUT=working.m3u; REP=report.txt
head -1 "$IN" | grep -q '^#EXTM3U' && head -1 "$IN" > "$OUT" || echo '#EXTM3U' > "$OUT"
: > "$REP"
ok=0; dead=0; info=""
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  case "$line" in
    '#EXTINF'*) info="$line"; continue ;;
    '#'*|'') continue ;;
  esac
  url="$line"; name="${info##*,}"; res="DEAD"
  case "$url" in
    http*youtube.com*) res="SKIP(youtube)" ;;
    http*)
      body=$(curl -sL --max-time 8 -A 'Mozilla/5.0' -r 0-2047 "$url" 2>/dev/null | head -c 2048 | tr -d '\0')
      if printf '%s' "$body" | grep -q '#EXTM3U'; then res="OK"
      elif [ -n "$body" ] && ! printf '%s' "$body" | grep -qi '<html'; then res="OK(raw)"; fi ;;
    *) res="DEAD(old-protocol)" ;;
  esac
  printf '%-22s %-30s %s\n' "$res" "$name" "$url" >> "$REP"
  if [[ "$res" == OK* ]]; then printf '%s\n%s\n' "$info" "$url" >> "$OUT"; ok=$((ok+1)); else dead=$((dead+1)); fi
  echo "[$res] $name"
done < "$IN"
echo; echo "Working: $ok   Dead: $dead"; echo "Saved: $OUT and $REP"
