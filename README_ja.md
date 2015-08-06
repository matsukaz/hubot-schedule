# hubot-schedule

\[English: [README.md](README.md)\]

hubot-scheduleはHubotで動作するメッセージスケジューラです。

`cron形式`と`日付形式`の２つの形式でスケジュール登録することができます。
時間指定のスケジューリングであり、インターバル指定ではありません。

hubot-scheduleはスケジュール管理に`node-schedule`を利用しています。そのため、いくつかのcronの機能がサポートされていません。
詳しくは[node-schedule](https://github.com/mattpat/node-schedule)をご覧ください。

このスクリプトは[hubot-cron](https://github.com/miyagawa/hubot-cron)に大きく影響を受けています。
元々時間指定のスケジューラが欲しかったのですが、node-scheduleがcron指定にも対応していたため、2つの形式をサポートしたスケジューラとして開発しました。



## インストール方法

`hubot-schedule`を`package.json`に追加します。

```
"dependencies": {
  "hubot-schedule": "~0.2.1"
}
```

`npm install`を実行します。

```
$ npm install
```

`hubot-schedule`を`external-scripts.json`に追加します.

```
> cat external-scripts.json
> ["hubot-schedule"]
```


## 使い方

```
Hubot> hubot help schedule
Hubot schedule [add|new] "<datetime pattern>" <message> - Schedule a message that runs on a specific date and time
Hubot schedule [add|new] "<cron pattern>" <message> - Schedule a message that runs recurrently
Hubot schedule [cancel|del|delete|remove] <id> - Cancel the schedule
Hubot schedule [upd|update] <id> <message> - Update scheduled message
Hubot schedule list - List all scheduled messages

Hubot> hubot schedule add "2015-01-16 10:00" スクリプトをリリースするよ！
6738: Schedule created

Hubot> hubot schedule add "0 10 * * 1-5" 朝のコーヒー淹れ忘れないでね :)
9735: Schedule created

Hubot> hubot schedule list
6738: [ Fri Jan 16 2015 10:00:00 GMT+0900 (JST) ] #Shell スクリプトをリリースするよ！
9735: [ 0 10 * * 1-5 ] #Shell 朝のコーヒー淹れ忘れないでね :)

Hubot> hubot schedule update 6738 スクリプトをリリースしてみんなにシェアしよう！
6738: Scheduled message updated

Hubot> hubot schedule list
6738: [ Fri Jan 16 2015 10:00:00 GMT+0900 (JST) ] #Shell スクリプトをリリースしてみんなにシェアしよう！
9735: [ 0 10 * * 1-5 ] #Shell 朝のコーヒー淹れ忘れないでね :)

スクリプトをリリースしてみんなにシェアしよう！
(2015-01-16 10:00:00になると投稿され、スケジュールから削除される)

Hubot> hubot schedule list
9735: [ 0 10 * * 1-5 ] #Shell 朝のコーヒー淹れ忘れないでね :)

Hubot> hubot schedule del 6738
6738: Schedule canceled

Hubot> hubot schedule list
Message is not scheduled


Hubot> hubot schedule add "0 10 * * 1-5" hubot image me コーヒー
9735: Schedule created
(hubotはhubot-scheduleによるメッセージを処理できるため、指定時間になったらコーヒー画像を表示する、といった利用が可能です。メッセージを処理させたくない場合には、環境変数に`HUBOT_SCHEDULE_DONT_RECEIVE=1`を設定します。)
```

スケジュール登録したメッセージを永続化したい場合は、[hubot-redis-brain](https://github.com/hubot-scripts/hubot-redis-brain)のようなhubot-brainの永続化モジュールを利用してください。

環境変数に`HUBOT_SCHEDULE_DEBUG=1`を設定することで、デバッグメッセージなどを表示することができます。


## Copyright and license

Copyright 2015 Masakazu Matsushita.

Licensed under the **[MIT License](LICENSE)**.

