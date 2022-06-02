#!/usr/bin/env ruby

require "json"
require "octokit"

json = File.read(ENV.fetch("GITHUB_EVENT_PATH"))
event = JSON.parse(json)

github = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])

if !ENV["GITHUB_TOKEN"]
  puts "Missing GITHUB_TOKEN"
  exit(1)
end

if ARGV.length < 2
  puts "Missing arguments."
  exit(1)
end

repo = event["repository"]["full_name"]

if ENV.fetch("GITHUB_EVENT_NAME") == "pull_request"
  pr_number = event["number"]
else
  pulls = github.pull_requests(repo, state: "open")

  push_head = event["after"]
  pr = pulls.find { |pr| pr["head"]["sha"] == push_head }

  if !pr
    puts "Couldn't find an open pull request for branch with head at #{push_head}."
    exit(1)
  end
  pr_number = pr["number"]
end
file_path = ARGV[0]
prefix = ARGV[1]
action = ARGV[2]

puts Dir.entries(".")

message = File.read(file_path)

coms = github.issue_comments(repo, pr_number)

com = coms.find { |com| com["body"].start_with?(prefix) }
if com == nil
  github.add_comment(repo, pr_number, prefix + "\n\n" + message)
else
  cur_time = Time.new
  timestamp = "\n\nUpdate on " + cur_time.inspect + "\n\n"

  if action == "replace"
    body = prefix + timestamp + message
  else
    body = com["body"] + timestamp + message
  end

  com = github.update_comment(repo, com["id"], body)
end
