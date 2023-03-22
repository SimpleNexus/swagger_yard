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
      (events + other.events).uniq.each do |event|
        merged_items[event] = (event_items[event] || EventItem.new) + (other.event_items[event] || EventItem.new)
      end
      Events.new(merged_items)
    end
  end
end
