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
