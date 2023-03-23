module SwaggerYard
  class EventItem
    attr_accessor :webhook_operations, :webhook

    def initialize(webhook = nil)
      @webhook = webhook
      @webhook_operations = {}
    end

    def add_webhook_operation(yard_object)
      webhook_operation = WebhookOperation.from_yard_object(yard_object, self)
      @webhook_operations[webhook_operation.http_method.downcase] = webhook_operation
    end

    def +(other)
      EventItem.new(webhook).tap do |ei|
        ei.webhook_operations = webhook_operations.merge(other.webhook_operations)
      end
    end
  end
end
