v0.7.0
======

* Add UTC Offset support for cron. As a result, hubot-schedule now depend on node-cron.

v0.6.2
======

* Fix schedule list not shown for the jobs created using v0.5.1 or below.

v0.6.1
======

* Fix channel name only resolved for public channel.

v0.6.0
======

* Support hubot-slack v4.x.

v0.5.1
======

* Fix serialization to strore room name correctly.

v0.5.0
======

* Add a command to control schedules from other rooms.
* Support multi-line messages.
* Add HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL configuration support.
* Schedule list is now sorted by due date.

v0.4.1
======

* Fix scheduled job not working on leap year.

v0.4.0
======

* Add default value for HUBOT_SCHEDULE_LIST_REPLACE_TEXT.


v0.3.0
======

* Add HUBOT_SCHEDULE_LIST_REPLACE_TEXT configuration support.


v0.2.1
======

* Fix scheduled messages not removed from cache.


v0.2.0
======

* Hubot can now process messages sent by hubot-schedule.



v0.1.0
======

* Intial release
