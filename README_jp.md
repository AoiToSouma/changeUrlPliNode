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
.envファイルに対して切り替え可能な httpUrl ($RPC_LIST) と wsUrl ($WS_LIST) を編集します。<br>
必要に応じてそのほかのパラメータも編集します。
```
cp sample.env .env
nano .env
```

# Execute
実行のパターンは下記の3種類です。<br>
1. RPC(httpUrl)のみ変更する
```
./netset.sh -t rpc
```
2. WS(wsUrl)のみ変更する
```
./netset.sh -t ws
```
3. RPC(httpUrl)とWS(wsUrl)を変更する
```
./netset.sh -t both
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
