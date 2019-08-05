# hubot-schedule

[README_ja.md](README_ja.md)

[![NPM version](https://badge.fury.io/js/hubot-schedule.png)](http://badge.fury.io/js/hubot-schedule)

[![NPM](https://nodei.co/npm/hubot-schedule.png?downloads=true)](https://nodei.co/npm/hubot-schedule/)

hubot-schedule is a message scheduler runs on hubot.

It allows you to schedule a message in both `cron-style` and `datetime-based` format pattern.
It is for time-based scheduling, not interval-based scheduling.

Since hubot-schedule uses node-schedule to manage schedule, some of the cron features are not supported.
Please see [node-schedule](https://github.com/mattpat/node-schedule) for more details.

This script is greatly inspired by [hubot-cron](https://github.com/miyagawa/hubot-cron).
At first, I wanted a datetime-based scheduler.
As I start developing this, I noticed that node-schedule also suppports cron-style scheduling, so I changed my mind to develop a scheduler that supports both cron-style and datetime-based format.


## Note

### for Slack users

If you are using slack adapter such as `hubot-slack`, please use `v4.2.2` or later.
`v4.2.1` sometimes fails to add new schedule.


## Installation

Add `hubot-schedule` to your `package.json`.

```
"dependencies": {
  "hubot-schedule": "~0.6.2"
}
```

Run `npm install`.

```
$ npm install
```

Add `hubot-schedule` to `external-scripts.json`.

```
> cat external-scripts.json
> ["hubot-schedule"]
```


## Usage

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

Hubot> hubot schedule add "2015-01-16 10:00" Let's release this script!
6738: Schedule created

Hubot> hubot schedule add "0 10 * * 1-5" Don't forget to brew coffee :)
9735: Schedule created

Hubot> hubot schedule list
6738: [ 2015-01-16 10:00:00 +09:00 ] #Shell Let's release this script!
9735: [ 0 10 * * 1-5 ] #Shell Don't forget to brew coffee :)

Hubot> hubot schedule update 6738 Let's release this module and share with everyone!
6738: Scheduled message updated

Hubot> hubot schedule list
6738: [ 2015-01-16 10:00:00 +09:00 ] #Shell Let's release this script and share with everyone!
9735: [ 0 10 * * 1-5 ] #Shell Don't forget to brew coffee :)

Let's release this script and share with everyone!
(Hubot posts the message at 2015-01-16 10:00:00 and schedule will be removed automatically)

Hubot> hubot schedule del 9735
9735: Schedule canceled

Hubot> hubot schedule list
Message is not scheduled

Hubot> hubot schedule add "0 10 * * 1-5" hubot image me coffee
9735: Schedule created
(hubot can process messages sent by hubot-schedule, so you can ask hubot to do something at the scheduled time, like post an image of coffee.)
```

If you need to persist scheduled messages, use hubot-brain persistent module like [hubot-redis-brain](https://github.com/hubot-scripts/hubot-redis-brain).

### How to use UTC Offset

If OS timezone is set to Asia/Tokyo（UTC Offset would be "+09:00"）

```
Hubot> hubot schedule env
DEBUG = false
DONT_RECEIVE = false
DENY_EXTERNAL_CONTROL = false
LIST_REPLACE_TEXT = {"@":"[@]"}
DEFAULT_UTC_OFFSET_FOR_CRON = "+09:00"

Hubot> hubot schedule add "2019-08-05 10:00 +02:00" use UTC Offset for datetime-based format pattern
2914: Schedule created

Hubot> hubot schedule add "0 10 * * 1-5, +02:00" use UTC Offset for cron-style format pattern
4291: Schedule created

Hubot> hubot schedule list
2914: [ 2019-08-05 17:00:00 +09:00 ] #Shell use UTC Offset for datetime-based format pattern (listed schedules are shown using OS timezone)
4291: [ 0 10 * * 1-5, +02:00 ] #Shell use UTC Offset for cron-style format pattern
```

## Configuration

### HUBOT_SCHEDULE_DEBUG

Setting environment variable `HUBOT_SCHEDULE_DEBUG=1` will show some debug messages.

### HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL

Setting environment variable `HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL=1` will deny schedule control from other rooms.

### HUBOT_SCHEDULE_DONT_RECEIVE

Setting environment variable `HUBOT_SCHEDULE_DONT_RECEIVE=1` will disable hubot not to process messages sent by hubot-schedule.

### HUBOT_SCHEDULE_LIST_REPLACE_TEXT

Setting environment variable `HUBOT_SCHEDULE_LIST_REPLACE_TEXT='<stringified json>'` will configure the text replacement used when listing scheduled messages.
Default configuration is `'{"@":"[@]"}'`.

### HUBOT_SCHEDULE_UTC_OFFSET_FOR_CRON

Setting environment variable `HUBOT_SCHEDULE_UTC_OFFSET_FOR_CRON='<string format UTC Offset(e.g. "+09:00")>'` will set default UTC Offset for cron-style format pattern.
If not set, OS timezone's offset would be used.

## Copyright and license

Copyright 2015 Masakazu Matsushita.

Licensed under the **[MIT License](LICENSE)**.
