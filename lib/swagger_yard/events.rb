module SwaggerYard
  class Events
    attr_reader :event_items

    def initialize(event_items={})
      @event_items = event_items
    end

    def events
      event_items.keys
    end

    def merge(other)
      merged_items = {}
      (events + other.events).each do |event|
        event_item = event_items[event] || EventItem.new
        other_event_item = other.event_items[event] || EventItem.new
        duplicate_operations = event_item.webhook_operations.keys & other_event_item.webhook_operations.keys
        if duplicate_operations.present?
          operations_info = duplicate_operations.map do |operation_key|
            resource = event_item.webhook_operations[operation_key].extended_attributes["x-api-resource"]
            other_resource = other_event_item.webhook_operations[operation_key].extended_attributes["x-api-resource"]
            resources_info = [resource, other_resource].compact.map do |r|
              "#{r["class"]}.#{r["method"]}"
            end
            info = "#{operation_key}"
            info += " (#{resources_info.join(", ")})" if resources_info.present?
            info
          end
          raise "Found duplicate operations for the same event (event: '#{event}', operations: #{operations_info.join(", ")})"
        end

        merged_items[event] = event_item + other_event_item
      end
      Events.new(merged_items)
    end
  end
end
