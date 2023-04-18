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
        path_item = path_items[path] || PathItem.new
        other_path_item = other.path_items[path] || PathItem.new
        duplicate_operations = path_item.operations.keys & other_path_item.operations.keys
        if duplicate_operations.present?
          operations_info = duplicate_operations.map do |operation_key|
            resource = path_item.operations[operation_key].extended_attributes["x-api-resource"]
            other_resource = other_path_item.operations[operation_key].extended_attributes["x-api-resource"]
            resources_info = [resource, other_resource].compact.map do |r|
              "#{r["class"]}.#{r["method"]}"
            end
            info = "#{operation_key}"
            info += " (#{resources_info.join(", ")})" if resources_info.present?
            info
          end
          raise "Found duplicate operations for the same path (path: '#{path}', operation(s): #{operations_info.join(", ")})"
        end

        merged_items[path] = path_item + other_path_item
      end
      Paths.new(merged_items)
    end
  end
end
