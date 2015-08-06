# hubot-schedule

\[Japanese: [README_ja.md](README_ja.md)\]

hubot-schedule is a message scheduler runs on hubot.

It allows you to schedule a message in both `cron-style` and `datetime-based` format pattern.
It is for time-based scheduling, not interval-based scheduling.

Since hubot-schedule uses node-schedule to manage schedule, some of the cron features are not supported.
Please see [node-schedule](https://github.com/mattpat/node-schedule) for more details.

This script is greatly inspired by [hubot-cron](https://github.com/miyagawa/hubot-cron).
At first, I wanted a datetime-based scheduler.
As I start developing this, I noticed that node-schedule also suppports cron-style scheduling, so I changed my mind to develop a scheduler that supports both cron-style and datetime-based format.



## Installation

Add `hubot-schedule` to your `package.json`.

```
"dependencies": {
  "hubot-schedule": "~0.2.1"
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
Hubot schedule [add|new] "<datetime pattern>" <message> - Schedule a message that runs on a specific date and time
Hubot schedule [add|new] "<cron pattern>" <message> - Schedule a message that runs recurrently
Hubot schedule [cancel|del|delete|remove] <id> - Cancel the schedule
Hubot schedule [upd|update] <id> <message> - Update scheduled message
Hubot schedule list - List all scheduled messages

Hubot> hubot schedule add "2015-01-16 10:00" Let's release this script!
6738: Schedule created

Hubot> hubot schedule add "0 10 * * 1-5" Don't forget to brew coffee :)
9735: Schedule created

Hubot> hubot schedule list
6738: [ Fri Jan 16 2015 10:00:00 GMT+0900 (JST) ] #Shell Let's release this script!
9735: [ 0 10 * * 1-5 ] #Shell Don't forget to brew coffee :)

Hubot> hubot schedule update 6738 Let's release this module and share with everyone!
6738: Scheduled message updated

Hubot> hubot schedule list
6738: [ Fri Jan 16 2015 10:00:00 GMT+0900 (JST) ] #Shell Let's release this script and share with everyone!
9735: [ 0 10 * * 1-5 ] #Shell Don't forget to brew coffee :)

Let's release this script and share with everyone!
(Hubot posts the message at 2015-01-16 10:00:00 and schedule will be removed automatically)

Hubot> hubot schedule del 9735
9735: Schedule canceled

Hubot> hubot schedule list
Message is not scheduled

Hubot> hubot schedule add "0 10 * * 1-5" hubot image me coffee
9735: Schedule created
(hubot can process messages sent by hubot-schedule, so you can ask hubot to do something at the scheduled time, like post an image of coffee. You can disable it by setting environment variable `HUBOT_SCHEDULE_DONT_RECEIVE=1`)
```

If you need to persist scheduled messages, use hubot-brain persistent module like [hubot-redis-brain](https://github.com/hubot-scripts/hubot-redis-brain).

Setting environment variable `HUBOT_SCHEDULE_DEBUG=1` will show some debug messages.


## Copyright and license

Copyright 2015 Masakazu Matsushita.

Licensed under the **[MIT License](LICENSE)**.

