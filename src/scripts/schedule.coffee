# Description:
#   Schedule a message in both cron-style and datetime-based format pattern
#
# Dependencies:
#   "node-schedule" : "~1.0.0",
#   "cron" : "~1.7.0",
#   "cron-parser"   : "~1.0.1"
#
# Configuration:
#   HUBOT_SCHEDULE_DEBUG - set "1" for debug
#   HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL - set "1" if you want to deny scheduling from other rooms
#   HUBOT_SCHEDULE_DONT_RECEIVE - set "1" if you don't want hubot to be processed by scheduled message
#   HUBOT_SCHEDULE_LIST_REPLACE_TEXT - set JSON object like '{"@":"[at]"}' to configure text replacement used when listing scheduled messages
#   HUBOT_SCHEDULE_UTC_OFFSET_FOR_CRON - set default UTC offset for cron pattern in string format like "+09:00"
#
# Commands:
#   hubot schedule [add|new] "<datetime pattern>" <message> - Schedule a message that runs on a specific date and time
#   hubot schedule [add|new] "<cron pattern>(,<utc offset>)" <message> - Schedule a message that runs recurrently.
#   hubot schedule [add|new] #<room> "<datetime pattern>" <message> - Schedule a message to a specific room that runs on a specific date and time
#   hubot schedule [add|new] #<room> "<cron pattern>(,<utc offset>)" <message> - Schedule a message to a specific room that runs recurrently
#   hubot schedule [cancel|del|delete|remove] <id> - Cancel the schedule
#   hubot schedule [upd|update] <id> <message> - Update scheduled message
#   hubot schedule list - List all scheduled messages for current room
#   hubot schedule list #<room> - List all scheduled messages for specified room
#   hubot schedule list all - List all scheduled messages for any rooms
#   hubot schedule env - Show hubot schedule environments
#
# Author:
#   matsukaz <matsukaz@gmail.com>

# configuration settings
config =
  debug: process.env.HUBOT_SCHEDULE_DEBUG
  dont_receive: process.env.HUBOT_SCHEDULE_DONT_RECEIVE
  deny_external_control: process.env.HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL
  list:
    replace_text: JSON.parse(process.env.HUBOT_SCHEDULE_LIST_REPLACE_TEXT ? '{"@":"[@]"}')
  utc_offset_for_cron: process.env.HUBOT_SCHEDULE_UTC_OFFSET_FOR_CRON

scheduler = require('node-schedule')
CronJob = require('cron').CronJob
cronParser = require('cron-parser')
{TextMessage} = require('hubot')
JOBS = {}
JOB_MAX_COUNT = 10000
STORE_KEY = 'hubot_schedule'

module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    syncSchedules robot

  if !robot.brain.get(STORE_KEY)
    robot.brain.set(STORE_KEY, {})

  robot.respond /schedule (?:new|add)(?: #(.*))? "(.*?)" ((?:.|\s)*)$/i, (msg) ->
    target_room = msg.match[1]

    if not is_blank(target_room) and isRestrictedRoom(target_room, robot, msg)
      return msg.send "Creating schedule for the other room is restricted"
    schedule robot, msg, target_room, msg.match[2], msg.match[3]


  robot.respond /schedule list(?: (all|#.*))?/i, (msg) ->
    target_room = msg.match[1]
    room_id = msg.message.user.room
    room_name = getRoomName(robot, msg.message.user)
    if is_blank(target_room) or config.deny_external_control is '1'
      # if target_room is undefined or blank, show schedule for current room
      # room is ignored when HUBOT_SCHEDULE_DENY_EXTERNAL_CONTROL is set to 1
      rooms = [room_name, msg.message.user.reply_to]
    else if target_room == "all"
      show_all = true
    else
      rooms = [target_room[1..]]

    # split jobs into date and cron pattern jobs
    dateJobs = {}
    cronJobs = {}
    for id, job of JOBS

      # backward compatibility
      # hubot-schedule under v0.5.1 holds it's job by room_id instead of room_name
      if job.user.room == room_id
        job.user.room = room_name

      if show_all or job.user.room in rooms
        if isCronPattern(job.pattern)
          cronJobs[id] = job
        else
          dateJobs[id] = job

    # sort by date in ascending order
    text = ''
    for id in (Object.keys(dateJobs).sort (a, b) -> new Date(dateJobs[a].pattern) - new Date(dateJobs[b].pattern))
      job = dateJobs[id]
      text += "#{id}: [ #{formatDate(new Date(job.pattern))} ] \##{job.user.room} #{job.message} \n"

    for id, job of cronJobs
      text += "#{id}: [ #{job.pattern} ] \##{job.user.room} #{job.message} \n"

    if !!text.length
      text = text.replace(///#{org_text}///g, replaced_text) for org_text, replaced_text of config.list.replace_text
    else
      text = 'No messages have been scheduled'

    msg.send text


  robot.respond /schedule (?:upd|update) (\d+) ((?:.|\s)*)/i, (msg) ->
    updateSchedule robot, msg, msg.match[1], msg.match[2]


  robot.respond /schedule (?:del|delete|remove|cancel) (\d+)/i, (msg) ->
    cancelSchedule robot, msg, msg.match[1]


  robot.respond /schedule env/i, (msg) ->
    showEnvironments robot, msg


schedule = (robot, msg, room, pattern, message) ->
  if JOB_MAX_COUNT <= Object.keys(JOBS).length
    return msg.send "Too many scheduled messages"

  id = Math.floor(Math.random() * JOB_MAX_COUNT) while !id? || JOBS[id]
  try
    job = createSchedule robot, id, pattern, msg.message.user, room, message
    if job
      msg.send "#{id}: Schedule created"
    else
      msg.send """
        \"#{pattern}\" is invalid pattern.
        See http://crontab.org/ for cron-style format pattern.
        See http://www.ecma-international.org/ecma-262/5.1/#sec-15.9.1.15 for datetime-based format pattern.
      """
  catch error
    return msg.send error.message


createSchedule = (robot, id, pattern, user, room, message) ->
  if isCronPattern(pattern)
    return createCronSchedule robot, id, pattern, user, room, message

  date = Date.parse(pattern)
  if !isNaN(date)
    if date < Date.now()
      throw new Error "\"#{pattern}\" has already passed"
    return createDatetimeSchedule robot, id, pattern, user, room, message


createCronSchedule = (robot, id, pattern, user, room, message) ->
  startSchedule robot, id, pattern, user, room, message


createDatetimeSchedule = (robot, id, pattern, user, room, message) ->
  startSchedule robot, id, pattern, user, room, message, () ->
    delete JOBS[id]
    delete robot.brain.get(STORE_KEY)[id]


startSchedule = (robot, id, pattern, user, room, message, cb) ->
  if !room
    room = getRoomName(robot, user)
  job = new Job(id, pattern, user, room, message, cb)
  job.start(robot)
  JOBS[id] = job
  robot.brain.get(STORE_KEY)[id] = job.serialize()


updateSchedule = (robot, msg, id, message) ->
  job = JOBS[id]
  return msg.send "Schedule #{id} not found" if !job

  if isRestrictedRoom(job.user.room, robot, msg)
    return msg.send "Updating schedule for the other room is restricted"

  job.message = message
  robot.brain.get(STORE_KEY)[id] = job.serialize()
  msg.send "#{id}: Scheduled message updated"


cancelSchedule = (robot, msg, id) ->
  job = JOBS[id]
  return msg.send "#{id}: Schedule not found" if !job

  if isRestrictedRoom(job.user.room, robot, msg)
    return msg.send "Canceling schedule for the other room is restricted"

  job.cancel()
  delete JOBS[id]
  delete robot.brain.get(STORE_KEY)[id]
  msg.send "#{id}: Schedule canceled"


showEnvironments = (robot, msg) ->
  text = ''
  text += "DEBUG = #{config.debug is '1'}\n"
  text += "DONT_RECEIVE = #{config.dont_receive is '1'}\n"
  text += "DENY_EXTERNAL_CONTROL = #{config.deny_external_control is '1'}\n"
  text += "LIST_REPLACE_TEXT = #{JSON.stringify(config.list.replace_text)}\n"
  if config.utc_offset_for_cron
    text += "DEFAULT_UTC_OFFSET_FOR_CRON = \"#{config.utc_offset_for_cron}\"\n"
  else
    text += "DEFAULT_UTC_OFFSET_FOR_CRON = \"#{getUTCOffset(new Date())}\"\n"

  msg.send text


syncSchedules = (robot) ->
  if !robot.brain.get(STORE_KEY)
    robot.brain.set(STORE_KEY, {})

  nonCachedSchedules = difference(robot.brain.get(STORE_KEY), JOBS)
  for own id, job of nonCachedSchedules
    scheduleFromBrain robot, id, job...

  nonStoredSchedules = difference(JOBS, robot.brain.get(STORE_KEY))
  for own id, job of nonStoredSchedules
    storeScheduleInBrain robot, id, job


scheduleFromBrain = (robot, id, pattern, user, message) ->
  envelope = user: user, room: user.room
  try
    createSchedule robot, id, pattern, user, user.room, message
  catch error
    robot.send envelope, "#{id}: Failed to schedule from brain. [#{error.message}]" if config.debug is '1'
    return delete robot.brain.get(STORE_KEY)[id]

  robot.send envelope, "#{id} scheduled from brain" if config.debug is '1'


storeScheduleInBrain = (robot, id, job) ->
  robot.brain.get(STORE_KEY)[id] = job.serialize()

  envelope = user: job.user, room: job.user.room
  robot.send envelope, "#{id}: Schedule stored in brain asynchronously" if config.debug is '1'


difference = (obj1 = {}, obj2 = {}) ->
  diff = {}
  for id, job of obj1
    diff[id] = job if id !of obj2
  return diff


isCronPattern = (pattern) ->
  errors = cronParser.parseString(pattern.split(',')[0]).errors
  return !Object.keys(errors).length


is_blank = (s) -> !s?.trim()


is_empty = (o) -> Object.keys(o).length == 0


isRestrictedRoom = (target_room, robot, msg) ->
  if config.deny_external_control is '1'
    if target_room not in [getRoomName(robot, msg.message.user), msg.message.user.reply_to]
      return true
  return false


toTwoDigits = (num) ->
  ('0' + num).slice(-2)


formatDate = (date) ->
  day = [date.getFullYear(), toTwoDigits(date.getMonth()+1), toTwoDigits(date.getDate())].join('-')
  time = [toTwoDigits(date.getHours()), toTwoDigits(date.getMinutes()), toTwoDigits(date.getSeconds())].join(':')
  tz = getUTCOffset(date)
  [day, time, tz].join(' ')


getUTCOffset = (date) ->
  offset = -date.getTimezoneOffset()
  sign = '+'
  if offset < 0
    offset = -offset
    sign = '-'
  sign + toTwoDigits(offset / 60) + ':' + toTwoDigits(offset % 60)


getRoomName = (robot, user) ->
  try
    # Slack adapter needs to convert from room identifier
    # https://slackapi.github.io/hubot-slack/upgrading
    return robot.adapter.client.rtm.dataStore.getChannelGroupOrDMById(user.room).name
  catch e
    return user.room


class Job
  constructor: (id, pattern, user, room, message, cb) ->
    @id = id
    @pattern = pattern.trim()

    # format cron pattern
    if isCronPattern(@pattern)
      datas = @pattern.split(',')
      @pattern = datas[0].trim()
      if datas[1] && datas[1].trim()
        @pattern += ', ' + datas[1].trim()
    
    @user = { room: (room || user.room) }
    @user[k] = v for k,v of user when k in ['id','team_id','name'] # copy only needed properties
    @message = message
    @cb = cb
    @job

  start: (robot) ->
    if isCronPattern(@pattern)
      datas = @pattern.split(',')
      cronPattern = datas[0]
      utcOffset = datas[1] ? config.utc_offset_for_cron ? getUTCOffset(new Date())
      @job = new CronJob(cronPattern, =>
        envelope = user: @user, room: @user.room
        robot.send envelope, @message
        robot.adapter.receive new TextMessage(@user, @message) unless config.dont_receive is '1'
        @cb?()
      , null, true, null, null, null, utcOffset
      )
    else 
      @job = scheduler.scheduleJob(new Date(@pattern), =>
        envelope = user: @user, room: @user.room
        robot.send envelope, @message
        robot.adapter.receive new TextMessage(@user, @message) unless config.dont_receive is '1'
        @cb?()
      )

  cancel: ->
    scheduler.cancelJob @job if @job
    @cb?()

  serialize: ->
    [@pattern, @user, @message]
