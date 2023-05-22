module SwaggerYard
  class PathItem
    attr_accessor :path, :operations, :api_group

    def initialize(path, api_group)
      @path = path
      @api_group = api_group
      @operations = {}
    end

    def add_operation(yard_object, is_paths_object:)
      operation = Operation.from_yard_object(yard_object, self, is_paths_object: is_paths_object)
      @operations[operation.http_method.downcase] = operation
      return operation
    end

    def merge(other)
      duplicate_operations = self.operations.keys & other.operations.keys
      if duplicate_operations.present?
        operations_info = duplicate_operations.map do |operation_key|
          resources_info = [self.resource_method(operation_key), other.resource_method(operation_key)].compact
          info = "#{operation_key}"
          info += " (defined in #{resources_info.join(" and ")})" if resources_info.present?
          info
        end
        raise "Found duplicate operations for the same path (path: '#{self.path}', operation(s): #{operations_info.join(", ")})"
      end
      self.operations.merge!(other.operations)
      return self
    end

    def resource_method(operation_key)
      resource = self.operations[operation_key].extended_attributes["x-api-resource"]
      return "#{resource["class"]}.#{resource["method"]}" if resource.present?
    end

    def +(other)
      self.merge(other)
    end
  end
end
