#!/bin/bash

source .env

get_target(){
    case "$1" in
        rpc)
            list=(${RPC_LIST[@]})
            ;;
        ws)
            list=(${WS_LIST[@]})
            ;;
        *)
            return 1
    esac
    seq_no=0
    hit_no=-1
    max_no=$((${#list[@]}-1))
    for var in ${list[@]}
    do
        if grep -q "$var" $CONFIG; then
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
    ret_val=($current_val $next_val)
    #return array (0:current_val, 1:next_val)
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
        ;;
    ws)
        flg_rpc=false
        flg_ws=true
        ;;
    both)
        flg_rpc=true
        flg_ws=true
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
        exit 1
    fi
fi

#get wsUrl value
if "${flg_ws}"; then
    ws=($(get_target "ws"))
    if [ $? -ne 0 ]; then
        echo "Current wsUrl is not in the list."
        exit 1
    fi
fi

#change config.toml
echo "[Change details]"
if "${flg_rpc}"; then
    sed -i -e "s|${rpc[0]}|${rpc[1]}|g" $CONFIG
    echo "${rpc[0]}     --->    ${rpc[1]}"
fi
if "${flg_ws}"; then
    sed -i -e "s|${ws[0]}|${ws[1]}|g" $CONFIG
    echo "${ws[0]}     --->    ${ws[1]}"
fi

echo
echo "[config.toml]"
cat $CONFIG | grep -e 'httpUrl' && cat $CONFIG | grep -e 'wsUrl'

echo
echo "[PM2 list before restart]"
pm2 list

echo
echo "[PM2 restart]"
pm2 restart NodeStartPM2

from_line=$(cat $PM2LOG | wc -l)
echo
echo "Collecting error logs...sleep ${WAIT}s"
sleep $WAIT
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
