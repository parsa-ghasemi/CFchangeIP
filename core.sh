#!/bin/bash


# telegram bot ($1=token, $2=chat_id, $3=message, $4=disable notifications)
  function telegram_message(){
    curl -s -X POST https://public-telegram-bypass.solyfarzane9040.workers.dev/bot$1/sendMessage -d chat_id=$2 -d text="$3" -d disable_notification="$4" > /dev/null
  }



  # get zone information of cloudflare ($1=zone-id, $2=email, $3=key)
  function cf_records_info(){
    request=$(curl --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$1/dns_records \
    --header 'Content-Type: application/json' \
    --header 'X-Auth-Email:'$2 \
    --header 'X-Auth-Key:'$3)
    
    cf_domains_count=$( echo $request | jq -r '.result_info | .total_count' )
    
    local i=0
    while [ $i -le $(( $cf_domains_count - 1 )) ]
      do
        cf_dns_ids[$i]=$( echo $request | jq -r '.result | .['$i'] | .id' )
        cf_dns_domains[$i]=$( echo $request | jq -r '.result | .['$i'] | .name' )     
        i=$(( $i + 1 ))
      done
  }


# update cloudflare domains ip ($1=ip, $2=zone-id, $3=email, $4=key, $5=andis, $6=proxied)
  function cf_records_update(){
    cf_records_info $2 $3 $4
    for i in $5
      do
       curl -XPUT \
            --header 'Content-Type: application/json' \
            --header 'X-Auth-Email:'$3 \
            --header 'X-Auth-Key:'$4 \
            --data '{
            "content": "'$1'",
            "name": "'${cf_dns_domains[$i]}'",
            "proxied": '$6',
            "type": "A"
          }' 'https://api.cloudflare.com/client/v4/zones/'$2'/dns_records/'${cf_dns_ids[$i]}
        i=$(( $i + 1 ))
      done      
    cf_records_info $2 $3 $4
    request=`echo $request | grep -c $1`

    if [ $request -ge "1" ]
    then
      message="cloudflare changed ip. - ($1)"
      telegram_message $telegram_token $telegram_chat_id "$message" '1'
    else
      message="cloudflare could not change ip. - ($1) - ($2)"
      telegram_message $telegram_token $telegram_chat_id "$message" '0'
    fi
  }
