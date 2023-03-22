module SwaggerYard
  class Paths
    attr_reader :path_items

    def initialize(path_items={})
      @path_items = path_items
    end

    def paths
      path_items.keys
    end

    def merge(other)
      merged_items = {}
      (paths + other.paths).uniq.each do |path|
        merged_items[path] = (path_items[path] || PathItem.new) + (other.path_items[path] || PathItem.new)
      end
      Paths.new(merged_items)
    end
  end
end
