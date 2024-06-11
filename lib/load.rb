module Lib
  module Load
    def self.yamls(path)
      Dir.glob(path).each_with_object({ "instances" => [] }) do |file, obj|
        obj["instances"] += YAML.load_file(file)["instances"]
      end
    end
  end
end