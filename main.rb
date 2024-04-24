#!/usr/bin/env ruby
# frozen_string_literal: true

require 'faraday'
require "yaml"

class Instance
  attr_accessor :name, :url, :request_feature, :request, :status, :body, :features, :request_time

  def initialize(name, url)
    @name = name
    @url = url
    @features = []
  end

  def self.run(yaml)
    name = yaml["name"]
    url = yaml["url"]
    features = yaml["features"]
    instance = new(name, url)
    timer = Time.now
    instance.request = Faraday.get(instance.url)
    instance.request_time = Time.now - timer
    instance.status = instance.request.status
    instance.body = instance.request.body
    instance.request_feature = yaml["request"]
    sleep 0.5

    instance.features = features&.map do |feature|
      f = Feature.new(url, feature["name"], feature["expected"], feature["required"])
      f.run(instance.body)
      f
    end || []

    instance
  end

  def valid?
    @features.all?(&:valid?) && @status == @request_feature["status"] && @request_time < @request_feature["max_request_time"]
  end

  def report
    return if valid?

    report = "Instance '[#{@name}](#{@url})' (#{@url})\n"
    invalids = @features.map do |feature|
      "    - #{feature.name} n'est pas présent" if feature.invalid?
    end.uniq.compact
    report += invalids.join("\n") if invalids.any?
    report += "    - La plateforme répond un status code #{@status} au lieu de #{@request_feature["status"]}" if @status != @request_feature["status"]
    report += "    - La plateforme répond en plus de #{@request_time}s (soit plus de #{@request_feature["max_request_time"]}s)" if @request_time > @request_feature["max_request_time"]
    report
  end
end

class Feature
  attr_reader :url, :name, :expected, :required
  attr_accessor :presence

  def initialize(url, name, expected, required)
    @url = url
    @name = name
    @expected = expected
    @required = required
  end

  def run(body)
    @presence = true if body.include? @expected
  end

  def valid?
    return true unless required

    presence == required
  end

  def invalid?
    !valid?
  end
end

def yamls(path)
  Dir.glob(path).each_with_object({ "instances" => [] }) do |file, obj|
    obj["instances"] += YAML.load_file(file)["instances"]
  end
end

url = ENV["ROCKETCHAT_WEBHOOK_URL"]
path = ARGV[0] || "conf/*.yml"
data = yamls(path)["instances"]

instances = data.map do |instance|
  Instance.run(instance)
end

reports = instances.map(&:report)

if url.empty? || url.nil?
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
