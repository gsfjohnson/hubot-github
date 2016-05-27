# Description:
#   Allow Hubot to manage your github organization members and teams
#
# Dependencies:
#   "github": "latest"
#   "lodash": "latest"
#
# Configuration:
#   HUBOT_GITHUB_KEY - Github Application Key
#   HUBOT_GITHUB_ORG - Github Organization Name
#   HUBOT_SLACK_ADMIN - Userid of slack admins who can use these commands
#
# Commands:
#   hubot gho help - github organizational commands
#
# Author:
#   Ollie Jennings <ollie@olliejennings.co.uk>

org = require './libs/org'
admins = []

##############################
# API Methods
##############################

isAdmin = (user) ->
  user.id.toString() in admins

ensureConfig = (out) ->
  out "Error: Github App Key is not specified" if not process.env.HUBOT_GITHUB_KEY
  out "Error: Github organization name is not specified" if not process.env.HUBOT_GITHUB_ORG
  out "Error: Slack Admin userid is not specified" if not process.env.HUBOT_AUTH_ADMIN
  return false unless (process.env.HUBOT_GITHUB_KEY and process.env.HUBOT_GITHUB_ORG and process.env.HUBOT_AUTH_ADMIN)
  true


# getOrgMember = (msg, username, orgName) ->
#   ensureConfig msg.send
#   github.orgs.getMember org: orgName, user: username, (err, res) ->
#     msg.reply "There was an error getting the details of org member: #{username}" if err
#     msg.send "#{username} is part of the organization: #{orgName}" unless err




module.exports = (robot) ->

  ensureConfig console.log
  if process.env.HUBOT_AUTH_ADMIN?
    admins = process.env.HUBOT_AUTH_ADMIN.split ','
  else
    admins = []
  org.init()

  robot.respond /gho$/i, (msg) ->
    org.summary robot, msg

  robot.respond /gho list (teams|members|repos)/i, (msg) ->
    org.list[msg.match[1]] msg

  robot.respond /gho list (public) (repos)/i, (msg) ->
    org.list[msg.match[2]] msg, msg.match[1]

  robot.respond /gho create (team|repo) (\w.+)/i, (msg) ->
    unless isAdmin msg.message.user
      msg.reply "Only admins can use `create` commands"
    else
      org.create[msg.match[1]] msg,  msg.match[2].split('/')[0], msg.match[2].split('/')[1]

  robot.respond /gho add (members|repos) (\w.+) to team (\w.+)/i, (msg) ->
    unless isAdmin msg.message.user
      msg.reply "Only admins can use `add` commands"
    else
      org.add[msg.match[1]] msg, msg.match[2], msg.match[3]

  robot.respond /gho remove (members|repos) (\w.+) from team (\w.+)/i, (msg) ->
    unless isAdmin msg.message.user
      msg.reply "Only admins can use `remove` commands"
    else
      org.remove[msg.match[1]] msg, msg.match[2], msg.match[3]

  robot.respond /gho delete (team) (\w.+)/, (msg) ->
    unless isAdmin msg.message.user
      msg.reply "Only admins can use the `delete` commands"
    else
      org.delete[msg.match[1]] msg, msg.match[2]

  robot.respond /gho help$/, (msg) ->
    robot.adapter.customMessage {
      channel: msg.message.user.name,
      text: "github organizational commands",
      attachments: [
        {
          fields: [
            { "title": "gho help", "value": "This helpful response!", "short": true }
            ,{ "title": "gho list (teams|members|repos)", "value": "List teams, members, or repos.", "short": true }
            ,{ "title": "gho list public repos", "value": "List public repos.", "short": true }
            ,{ "title": "gho create team <name>", "value": "Creates a team with <name>.", "short": true }
            ,{ "title": "gho delete team <team>", "value": "Delete given team from organization.", "short": true }
            ,{ "title": "gho create repo <repo>/(public|private)", "value": "Create a repo with <repo> and type (public or private).", "short": false }
            ,{ "title": "gho add (members|repos) <members|repos> to team <team>", "value": "Adds a comma separated list of members or repos to <team>.", "short": false }
            ,{ "title": "gho remove (repos|members) <members|repos> from team <team>", "value": "Remove given repos or members from the given team.", "short": false }
          ]
        }
      ]
    }
