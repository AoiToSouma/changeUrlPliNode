#!/bin/bash

source .env

get_target(){
    case "$1" in
        rpc)
            list=(${RPC_LIST[@]})
            prefix="^\s*httpUrl.*"
            ;;
        ws)
            list=(${WS_LIST[@]})
            prefix="^\s*wsUrl.*"
            ;;
        *)
            return 1
    esac
    seq_no=0
    hit_no=-1 #Array number of hit list
    line_no=0 #Line number of config.toml that was hit
    max_no=$((${#list[@]}-1))
    for var in ${list[@]}
    do
        line_no=$(cat $CONFIG | grep -n "${prefix}${var}" | cut -f 1 -d ":")
        if [ "${line_no}" != "" ]; then
            hit_no=$seq_no
            current_val=$var
            break
        fi
        ((seq_no++))
    done
   if [ $hit_no -eq -1 ]; then
        #not found
        return 1
    fi
    if [ $hit_no -eq $max_no ]; then
        next_no=0
    else
        next_no=$((hit_no+1))
    fi
    next_val=${list[$next_no]}
    ret_val=($line_no $current_val $next_val)
    #return array (0:config line no, 1:current_val, 2:next_val)
    echo ${ret_val[@]}
    return 0
}

get_paired_target(){
    seq_no=0
    hit_no=-1     #Array number of hit list
    rpc_line_no=0 #Line number of config.toml that was hit(RPC)
    ws_line_no=0  #Line number of config.toml that was hit(WS)
    max_no=$((${#PAIR_LIST[@]}-1))
    rpc_prefix="^\s*httpUrl.*"
    ws_prefix="^\s*wsUrl.*"
    for var in ${PAIR_LIST[@]}
    do
        url=(${var//,/ })
        if grep -q "${rpc_prefix}${url[0]}" $CONFIG && grep -q "${ws_prefix}${url[1]}" $CONFIG; then
            hit_no=$seq_no
            current_val=(${url[@]})
            rpc_line_no=$(cat $CONFIG | grep -n "${rpc_prefix}${url[0]}" | cut -f 1 -d ":")
            ws_line_no=$(cat $CONFIG | grep -n "${ws_prefix}${url[1]}" | cut -f 1 -d ":")
            break
        fi
        ((seq_no++))
    done
    if [ $hit_no -eq -1 ]; then
        #not found
        return 1
    fi
    if [ $hit_no -eq $max_no ]; then
        next_no=0
    else
        next_no=$((hit_no+1))
    fi
    next_val=${PAIR_LIST[$next_no]}
    next_val=(${next_val//,/ })
    ret_val=("${rpc_line_no} ${ws_line_no} ${current_val[@]} ${next_val[@]}")
    #return array (0:rpc config line no 1:ws config line no 2:current_rpc, 3:current_ws, 4:next_rpc, 5:next_ws)
    echo ${ret_val[@]}
    return 0
}

while getopts t: flag
do
    case "${flag}" in
        t) type=${OPTARG};;
    esac
done

case "$type" in
    rpc)
        flg_rpc=true
        flg_ws=false
        flg_pair=false
        ;;
    ws)
        flg_rpc=false
        flg_ws=true
        flg_pair=false
        ;;
    both)
        flg_rpc=true
        flg_ws=true
        flg_pair=false
        ;;
    pair)
        flg_rpc=false
        flg_ws=false
        flg_pair=true
        ;;
    *)
        echo
        echo "Usage: $0 -t {option}"
        echo
        echo "where {option} is one of the following;"
        echo
        echo "    rpc    == change httpUrl"
        echo "    ws     == change wsUrl"
        echo "    both   == change httpUrl and wsUrl"
        echo "    pair   == change httpUrl and wsUrl with Pair List"
        echo
        exit 1
esac

#chainID check
grep "ChainID" $CONFIG | grep -q "$CHAINID"
if [ $? -ne 0 ]; then
    echo "ChainID does not match(ChainID=$CHAINID in .env)."
    exit 1
fi

#get httpUrl value
if "${flg_rpc}"; then
    rpc=($(get_target "rpc"))
    if [ $? -ne 0 ]; then
        echo "Current httpUrl is not in the list."
        echo "check RPC_LIST in .env."
        exit 1
    fi
fi

#get wsUrl value
if "${flg_ws}"; then
    ws=($(get_target "ws"))
    if [ $? -ne 0 ]; then
        echo "Current wsUrl is not in the list."
        echo "check WS_LIST in .env."
        exit 1
    fi
fi

#get paired value
if "${flg_pair}"; then
    pair=($(get_paired_target))
    if [ $? -ne 0 ]; then
        echo "Current pair is not in the list."
        echo "check PAIR_LIST in .env."
        exit 1
    fi
    rpc[0]=${pair[0]} #line number of config.toml that was hit(RPC)
    rpc[1]=${pair[2]} #Current RPC URL
    rpc[2]=${pair[4]} #Next RPC URL
    ws[0]=${pair[1]}  #line number of config.toml that was hit(WS)
    ws[1]=${pair[3]}  #Current WS URL
    ws[2]=${pair[5]}  #Next WS URL
    flg_rpc=true
    flg_ws=true
fi

#change config.toml
echo "[Change details]"
if "${flg_rpc}"; then
    sed -i -e "${rpc[0]} s|${rpc[1]}|${rpc[2]}|g" $CONFIG
    echo "${rpc[1]}     --->    ${rpc[2]}"
fi
if "${flg_ws}"; then
    sed -i -e "${ws[0]} s|${ws[1]}|${ws[2]}|g" $CONFIG
    echo "${ws[1]}     --->    ${ws[2]}"
fi

echo
echo "[config.toml]"
cat $CONFIG | grep -e '^\s*httpUrl' && cat $CONFIG | grep -e '^\s*wsUrl'

echo
echo "[PM2 reset]"
pm2 reset NodeStartPM2

echo
echo "[PM2 restart]"
pm2 restart NodeStartPM2

from_line=$(cat $PM2LOG | wc -l)
echo
echo "Collecting error logs...sleep ${WAIT}s"
count=$WAIT
while true
do
    printf "$count"
    if [ $count -eq 0 ]; then
        echo
        break
    else
        printf "..."
    fi
    ((count--))
    sleep 1
done
to_line=$(cat $PM2LOG | wc -l)

echo
echo "[PM2 list after restart]"
pm2 list
echo
echo "[PM2 Log error excerpt]"
sed -n ${from_line},${to_line}p $PM2LOG | grep -e '\[ERROR\]' -e '\[CRIT\]'
if [ $? -ne 0 ]; then
    echo "No errors occurred." 
    echo "Switching completed successfully."
fi
