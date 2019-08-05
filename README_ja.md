# hubot-schedule

[README.md](README.md)

[![NPM version](https://badge.fury.io/js/hubot-schedule.png)](http://badge.fury.io/js/hubot-schedule)

[![NPM](https://nodei.co/npm/hubot-schedule.png?downloads=true)](https://nodei.co/npm/hubot-schedule/)

hubot-scheduleはHubotで動作するメッセージスケジューラです。

`cron形式`と`日付形式`の２つの形式でスケジュール登録することができます。
時間指定のスケジューリングであり、インターバル指定ではありません。

hubot-scheduleはスケジュール管理に`node-schedule`を利用しています。そのため、いくつかのcronの機能がサポートされていません。
詳しくは[node-schedule](https://github.com/mattpat/node-schedule)をご覧ください。

このスクリプトは[hubot-cron](https://github.com/miyagawa/hubot-cron)に大きく影響を受けています。
元々時間指定のスケジューラが欲しかったのですが、node-scheduleがcron指定にも対応していたため、2つの形式をサポートしたスケジューラとして開発しました。


## 注意点

### Slack利用時

Slackを利用されている場合、`hubot-slack` は `v4.2.2` 以上をご利用ください。`v4.2.1` を利用すると、スケジュール登録に失敗することがあります。


## インストール方法

`hubot-schedule`を`package.json`に追加します。

```
"dependencies": {
  "hubot-schedule": "~0.7.0"
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
Hubot schedule [add|new] "<cron pattern>(,<utc offset>)" <message> - Schedule a message that runs recurrently
Hubot schedule [add|new] "<datetime pattern>" <message> - Schedule a message that runs on a specific date and time
Hubot schedule [add|new] #<room> "<cron pattern>(,<utc offset>)" <message> - Schedule a message to a specific room that runs recurrently
Hubot schedule [add|new] #<room> "<datetime pattern>" <message> - Schedule a message to a specific room that runs on a specific date and time
Hubot schedule [cancel|del|delete|remove] <id> - Cancel the schedule
Hubot schedule [upd|update] <id> <message> - Update scheduled message
Hubot schedule env - Show hubot schedule environments
Hubot schedule list #<room> - List all scheduled messages for specified room
Hubot schedule list - List all scheduled messages for current room
Hubot schedule list all - List all scheduled messages for any rooms

Hubot> hubot schedule add "2015-01-16 10:00" スクリプトをリリースするよ！
6738: Schedule created

Hubot> hubot schedule add "0 10 * * 1-5" 朝のコーヒー淹れ忘れないでね :)
9735: Schedule created

Hubot> hubot schedule list
6738: [ 2015-01-16 10:00:00 +09:00 ] #Shell スクリプトをリリースするよ！
9735: [ 0 10 * * 1-5 ] #Shell 朝のコーヒー淹れ忘れないでね :)

Hubot> hubot schedule update 6738 スクリプトをリリースしてみんなにシェアしよう！
6738: Scheduled message updated

Hubot> hubot schedule list
6738: [ 2015-01-16 10:00:00 +09:00 ] #Shell スクリプトをリリースしてみんなにシェアしよう！
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
(hubotはhubot-scheduleによるメッセージを処理できるため、指定時間になったらコーヒー画像を表示する、といった利用が可能です。)
```

スケジュール登録したメッセージを永続化したい場合は、[hubot-redis-brain](https://github.com/hubot-scripts/hubot-redis-brain)のようなhubot-brainの永続化モジュールを利用してください。

### UTC Offsetの利用方法

OSのタイムゾーンがAsia/Tokyoの場合（UTC Offsetが"+09:00"）

```
Hubot> hubot schedule env
DEBUG = false
DONT_RECEIVE = false
DENY_EXTERNAL_CONTROL = false
LIST_REPLACE_TEXT = {"@":"[@]"}
DEFAULT_UTC_OFFSET_FOR_CRON = "+09:00"

Hubot> hubot schedule add "2019-08-05 10:00 +02:00" 日付形式のスケジュール登録時にUTC Offsetを指定
2914: Schedule created

Hubot> hubot schedule add "0 10 * * 1-5, +02:00" cron形式のスケジュール登録時にUTC Offsetを指定
4291: Schedule created

Hubot> hubot schedule list
2914: [ 2019-08-05 17:00:00 +09:00 ] #Shell 日付形式のスケジュール登録時にUTC Offsetを指定 (list表示時はOSのタイムゾーンで表示)
4291: [ 0 10 * * 1-5, +02:00 ] #Shell cron形式のスケジュール登録時にUTC Offsetを指定
```


## 設定

### HUBOT_SCHEDULE_DEBUG

環境変数に`HUBOT_SCHEDULE_DEBUG=1`を設定することで、デバッグメッセージなどを表示することができます。

### HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL

他のルームからスケジュールを操作されたくない場合は、環境変数に`HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL=1`を設定します。

### HUBOT_SCHEDULE_DONT_RECEIVE

hubotにhubot-scheduleから送られたメッセージを処理させたくない場合には、環境変数に`HUBOT_SCHEDULE_DONT_RECEIVE=1`を設定します。

### HUBOT_SCHEDULE_LIST_REPLACE_TEXT

環境変数に`HUBOT_SCHEDULE_LIST_REPLACE_TEXT='<文字列化したJSON>'`を設定することで、スケジュールをリスト表示する際に文字を置換することができます。デフォルトの設定は`'{"@":"[@]"}'`です。

### HUBOT_SCHEDULE_UTC_OFFSET_FOR_CRON

環境変数に`HUBOT_SCHEDULE_UTC_OFFSET_FOR_CRON='<文字列形式のUTCオフセット(e.g. "+09:00")>'` を設定することで、cron形式のスケジュールのデフォルトのUTCオフセットを設定します。設定しなかった場合は、OSのタイムゾーンなどが利用されます。


## Copyright and license

Copyright 2015 Masakazu Matsushita.

Licensed under the **[MIT License](LICENSE)**.
