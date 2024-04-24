#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require "yaml"
require_relative 'lib/instance'
require_relative 'lib/feature'

def yamls(path)
  Dir.glob(path).each_with_object({ "instances" => [] }) do |file, obj|
    obj["instances"] += YAML.load_file(file)["instances"]
  end
end

url = ENV.fetch("ROCKETCHAT_WEBHOOK_URL", nil)
path = ARGV[0] || "conf/*.yml"
data = yamls(path)["instances"]

instances = data.map do |instance|
  Instance.run(instance)
end

reports = instances.map(&:report)

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
