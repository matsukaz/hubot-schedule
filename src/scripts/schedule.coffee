# Description:
#   Schedule a message in both cron-style and datetime-based format pattern
#
# Commands:
#   hubot schedule [add|new] "<datetime pattern>" <message> - Schedule a message that runs on a specific date and time
#   hubot schedule [add|new] "<cron pattern>" <message> - Schedule a message that runs recurrently
#   hubot schedule [cancel|del|delete|remove] <id> - Cancel the schedule
#   hubot schedule [upd|update] <id> <message> - Update scheduled message
#   hubot schedule list - List all scheduled messages
#
# Author:
#   matsukaz

scheduler = require('node-schedule')
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

  robot.respond /schedule (?:new|add) "(.*?)" (.*)$/i, (msg) ->
    schedule robot, msg, msg.match[1], msg.match[2]

  robot.respond /schedule list/i, (msg) ->
    text = ''
    for id, job of JOBS
      room = job.user.room || job.user.reply_to
      if room in [msg.message.user.room, msg.message.user.reply_to]
        text += "#{id}: [ #{job.pattern} ] \##{room} #{job.message} \n"
    if !!text.length
      msg.send text
    else
      msg.send 'Message is not scheduled'

  robot.respond /schedule (?:upd|update) (\d+) (.*)/i, (msg) ->
    updateSchedule robot, msg, msg.match[1], msg.match[2]

  robot.respond /schedule (?:del|delete|remove|cancel) (\d+)/i, (msg) ->
    cancelSchedule robot, msg, msg.match[1]


schedule = (robot, msg, pattern, message) ->
  if JOB_MAX_COUNT <= Object.keys(JOBS).length
    return msg.send "Too many scheduled messages"

  id = Math.floor(Math.random() * JOB_MAX_COUNT) while !id? || JOBS[id]
  try
    job = createSchedule robot, id, pattern, msg.message.user, message
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


createSchedule = (robot, id, pattern, user, message) ->
  if isCronPattern(pattern)
    return createCronSchedule robot, id, pattern, user, message
  
  date = Date.parse(pattern)
  if !isNaN(date)
    if date < Date.now()
      throw new Error "\"#{pattern}\" has already passed"
    return createDatetimeSchedule robot, id, pattern, user, message


createCronSchedule = (robot, id, pattern, user, message) ->
  startSchedule robot, id, pattern, user, message


createDatetimeSchedule = (robot, id, pattern, user, message) ->
  startSchedule robot, id, new Date(pattern), user, message, () ->
    delete JOBS[id]
    delete robot.brain.get(STORE_KEY)[id]


startSchedule = (robot, id, pattern, user, message, cb) ->
  job = new Job(id, pattern, user, message, cb)
  job.start(robot)
  JOBS[id] = job
  robot.brain.get(STORE_KEY)[id] = job.serialize()


updateSchedule = (robot, msg, id, message) ->
  job = JOBS[id]
  return msg.send "Schedule #{id} not found" if !job

  job.message = message
  robot.brain.get(STORE_KEY)[id] = job.serialize()
  msg.send "#{id}: Scheduled message updated"


cancelSchedule = (robot, msg, id) ->
  job = JOBS[id]
  return msg.send "#{id}: Schedule not found" if !job

  job.cancel()
  delete JOBS[id]
  delete robot.brain.get(STORE_KEY)[id]
  msg.send "#{id}: Schedule canceled"


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
    createSchedule robot, id, pattern, user, message
  catch error
    robot.send envelope, "#{id}: Failed to schedule from brain. [#{error.message}]" if process.env.HUBOT_SCHEDULE_DEBUG is '1'
    return delete robot.brain.get(STORE_KEY)[id]

  robot.send envelope, "#{id} scheduled from brain" if process.env.HUBOT_SCHEDULE_DEBUG is '1'


storeScheduleInBrain = (robot, id, job) ->
  robot.brain.get(STORE_KEY)[id] = job.serialize()

  envelope = user: job.user, room: job.user.room
  robot.send envelope, "#{id}: Schedule stored in brain asynchronously" if process.env.HUBOT_SCHEDULE_DEBUG is '1'


difference = (obj1 = {}, obj2 = {}) ->
  diff = {}
  for id, job of obj1
    diff[id] = job if id !of obj2
  return diff


isCronPattern = (pattern) ->
  errors = cronParser.parseString(pattern).errors
  return !Object.keys(errors).length


class Job
  constructor: (id, pattern, user, message, cb) ->
    @id = id
    @pattern = pattern
    # cloning user because adapter may touch it later
    @user = {}
    @user[k] = v for k,v of user
    @message = message
    @cb = cb
    @job

  start: (robot) ->
    @job = scheduler.scheduleJob(@pattern, =>
      envelope = user: @user, room: @user.room
      robot.send envelope, @message
      robot.adapter.receive new TextMessage(@user, @message) unless process.env.HUBOT_SCHEDULE_DONT_RECEIVE is '1'
      @cb?()
    )

  cancel: ->
    scheduler.cancelJob @job if @job
    @cb?()
    
  serialize: ->
    [@pattern, @user, @message]



