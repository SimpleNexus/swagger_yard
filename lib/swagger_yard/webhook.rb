module SwaggerYard
  class Webhook
    attr_accessor :description, :webhook_resource
    attr_reader :event_items, :authorizations, :class_name, :tag_group

    def self.from_yard_object(yard_object)
      new.add_yard_object(yard_object)
    end

    def initialize
      @webhook_resource = nil
      @event_items = {}
      @authorizations = {}
    end

    def valid?
      !@webhook_resource.nil?
    end

    def events
      Events.new(event_items)
    end

    def tag
      @tag ||= Tag.new(webhook_resource, description)
    end

    def add_yard_object(yard_object)
      return self if yard_object.visibility == :private && !SwaggerYard.config.include_private

      case yard_object.type
      when :class # controller
        add_info(yard_object)
        if valid?
          yard_object.children.each do |child_object|
            add_yard_object(child_object)
          end
        end
      when :method # actions
        add_event_item(yard_object)
      end
      self
    end

    def add_info(yard_object)
      @description = yard_object.docstring
      @class_name  = yard_object.path

      if tag = yard_object.tags.detect {|t| t.tag_name == "webhook_group"}
        @webhook_resource = tag.text
      end

      if tag = yard_object.tags.detect {|t| t.tag_name == "tag_group"}
        @tag_group = tag.text
      end

      # we only have api_key auth, the value for now is always empty array
      @authorizations = Hash[yard_object.tags.
                             select {|t| t.tag_name == "authorize_with"}.
                             map(&:text).uniq.
                             map {|k| [k, []]}]
    end

    def add_event_item(yard_object)
      event = event_from_yard_object(yard_object)
      operation = WebhookOperation.from_yard_object(yard_object, self)

      return if event.nil? || (operation.internal? && SwaggerYard.config.ignore_internal)

      event_item = (event_items[event] ||= EventItem.new(self))
      event_item.add_webhook_operation(yard_object)
      event
    end

    def event_from_yard_object(yard_object)
      yard_object.tags.detect {|t| t.tag_name == "event"}&.text
    end
  end
end
