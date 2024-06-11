#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require "yaml"
require_relative 'lib/instance'
require_relative 'lib/feature'
require_relative 'lib/load'

begin
  url = ENV.fetch("ROCKETCHAT_WEBHOOK_URL", nil)
  path = ARGV[0] || "conf/*.yml"
  data = Lib::Load.yamls(path)["instances"]

  threads = []
  data.each do |instance|
    threads << Thread.new { Instance.run(instance) }
  end

  threads.each(&:join)

  reports = threads.map { |instance| instance.value.report rescue instance.value.name }

  if url.nil? || url.empty?
    puts reports
    exit 0
  end

  if reports.any?
    payload = {
      "alias" => "ControlTower Bot",
      "emoji" => ":voisins_vigilants_et_solidaires:",
      "text" => reports.join("\n"),
    }

    Faraday.post(url, payload.to_json, "Content-Type" => "application/json")
    puts status: "invalid", message: "Reporting", payload: reports.join("\n")
  else
    puts status: "success", message: "All good !"
  end
rescue => e
  puts status: "error", message: e.message, backtrace: e.backtrace
end