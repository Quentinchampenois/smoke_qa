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
    conn = Faraday.new do |conn|
      conn.options.timeout = 10
    end
    instance.request = conn.get(instance.url)
    instance.request_time = Time.now - timer
    instance.status = instance.request.status
    instance.body = instance.request.body
    instance.request_feature = yaml["request"]

    instance.features = features&.map do |feature|
      f = Feature.new(url, feature["name"], feature["expected"], feature["required"])
      body = instance.body.force_encoding('UTF-8')
      f.run(body)
      f
    end || []

    instance

  rescue StandardError => e
    puts "Error: #{e.message}"
    instance.status = 408
    instance.request_feature = []
    instance.features = []
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
