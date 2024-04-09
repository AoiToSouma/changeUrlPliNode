# changeUrlPliNode
[README English](https://github.com/AoiToSouma/changeUrlPliNode/blob/main/README.md)<br>
PluginV2がセットアップされていることを前提としています。<br>
config.tomlのRPC(httpUrl)とWS(wsUrl)を切り替える機能です。

# Install the repo
```
git clone https://github.com/AoiToSouma/changeUrlPliNode.git
cd changeUrlPliNode
chmod +x *.sh
```

# Editing .env
sample.envをコピーし、.envファイルを作成します。<br>
.envファイルに対して切り替え可能な httpUrl ($RPC_LIST) と wsUrl ($WS_LIST)または組み合わせ ($PAIR_LIST) を編集します。<br>
コメント行(#...)は無視されます。<br>
現在のconfig.tomlで指定されているhttpUrl, wsUrlがリストに存在している必要があります。存在しない場合はエラーとなります。<br>
<br>
必要に応じてそのほかのパラメータも編集します。<br>
```
cp sample.env .env
nano .env
```

# Execute
実行のパターンは下記の4種類です。<br>
1. RPC(httpUrl)のみ変更する<br>
.env の $RPC_LIST を参照します。
```
./netset.sh -t rpc
```
2. WS(wsUrl)のみ変更する<br>
.env の $WS_LIST を参照します。
```
./netset.sh -t ws
```
3. RPC(httpUrl)とWS(wsUrl)を変更する<br>
.env の $RPC_LISTと$WS_LIST を参照します。
```
./netset.sh -t both
```
4. RPC(httpUrl)とWS(wsUrl)の組み合わせを変更する<br>
.env の $PAIR_LIST を参照します。
```
./netset.sh -t pair
```
<br>
config.tomlの変更後、"pm2 restart"が実行されます。<br>
そして、指定した時間pm2 ログをチェックし、[ERROR]および[CRIT]のエラーメッセージを収集します。<br>
ログを収集する時間は.envにて変更できます。<br>
[PM2 Log error excerpt]に下記のメッセージが表示された場合、エラーなく切り替えが完了しています。

```
No errors occurred.
Switching completed successfully.
```
