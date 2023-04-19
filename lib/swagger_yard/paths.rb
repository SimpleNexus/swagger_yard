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
      other.path_items.each do |path, other_path_item|
        if self.path_items.key?(path)
          self.path_items[path].merge(other_path_item)
        else
          self.path_items[path] = other_path_item
        end
      end
      return self
    end
  end
end
