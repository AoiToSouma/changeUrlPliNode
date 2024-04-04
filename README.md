# changeUrlPliNode
[README Japanese](https://github.com/AoiToSouma/changeUrlPliNode/blob/main/README_jp.md)<br>
It is assumed that pluginV2 is set up.<br>
This is a function to switch httpUrl and wsUrl in config.toml.

# Install the repo
```
git clone https://github.com/AoiToSouma/changeUrlPliNode.git
cd changeUrlPliNode
chmod +x *.sh
```

# Editing .env
Copy sample.env and create a .env file.<br>
Edit switchable httpUrl ($RPC_LIST) and wsUrl ($WS_LIST).<br>
Edit other parameters as necessary.
```
cp sample.env .env
nano .env
```

# Execute
Execution is performed using three types of parameters.<br>
1. Change only RPC(httpUrl)<br>
Reference $RPC_LIST in .env.
```
./netset.sh -t rpc
```
2. Change only WS(wsUrl)<br>
Reference $WS_LIST in .env.
```
./netset.sh -t ws
```
3. Change RPC(httpUrl) and WS(wsUrl)<br>
Reference $RPC_LIST and $WS_LIST in .env.
```
./netset.sh -t both
```
4. Change the combination of RPC(httpUrl) and WS(wsUrl) or combination($PAIR_LIST).<br>
Reference $PAIR_LIST in .env.
```
./netset.sh -t pair
```
<br>
After editing config.toml, perform "pm2 restart".<br>
Then, check the log at the specified time pm2 and collect [ERROR] and [CRIT] messages.<br>
The time to collect logs can be changed in .env.<br>
If the following message is output to [PM2 Log error excerpt], switching has been completed without an error.

```
No errors occurred.
Switching completed successfully.
```
