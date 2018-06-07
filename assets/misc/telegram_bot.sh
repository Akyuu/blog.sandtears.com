#!/bin/bash

token="this_is_my_token"
timeout=60
offset=0

while true
do
    result=`curl -s "https://api.telegram.org/bot${token}/getUpdates?offset=${offset}&timeout=${timeout}"`
    offset=$[`echo $result | grep -o \"update_id\":\[0-9\]\* | grep -o "[0-9]\+" | tail -1`+1]
    size=`echo $result | grep -o \"update_id\":\[0-9\]\* |  wc -l`

    for ((i=1; i<=$size; i++))
    do
        from=`echo $result | grep -o \"from\"\:\{\"id\":\[0-9\]\* | grep -o "[0-9]\+" | sed -n "${i}p"`
        msg=`echo $result | grep -o text\":\".\*\"\} | sed -n "${i}p" | cut -b 8- | cut -d \" -f 1`
        curl -H "Content-Type: application/json" --data "{\"chat_id\":$from,\"text\":\"$msg\"}" "https://api.telegram.org/bot${token}/sendMessage"
    done
done