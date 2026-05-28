#!/usr/bin/env bash

data=$(curl -s 'wttr.in/?format=%C+%t')

condition=$(echo "$data" | cut -d' ' -f1)
temp=$(echo "$data" | grep -o '[+-].*')

case "$condition" in
    *Sunny*) icon="󰖙" ;;
    *Clear*) icon="󰖙" ;;
    *Cloud*) icon="󰖐" ;;
    *Rain*) icon="󰖗" ;;
    *Thunder*) icon="󰖓" ;;
    *) icon="󰖐" ;;
esac

echo "{\"text\":\"$icon $temp\",\"tooltip\":\"$data\"}"
