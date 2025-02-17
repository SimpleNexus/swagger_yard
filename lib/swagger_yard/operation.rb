module SwaggerYard
  class Operation
    attr_accessor :description, :ruby_method
    attr_writer :summary
    attr_writer :operation_id
    attr_reader :path, :http_method
    attr_reader :parameters
    attr_reader :path_item, :responses, :extensions

    # TODO: extract to operation builder?
    def self.from_yard_object(yard_object, path_item, is_paths_object:)
      new(path_item).tap do |operation|
        operation.ruby_method = yard_object.name(false)
        operation.description = yard_object.docstring
        yard_object.tags.each do |tag|
          case tag.tag_name
          when "path"
            if is_paths_object
              tag = SwaggerYard.requires_type(tag)
              operation.add_path_params_and_method(tag) if tag
            end
          when "event"
            operation.add_path_params_and_method(tag)
          when "parameter"
            operation.add_parameter(tag)
          when "response_type"
            tag = SwaggerYard.requires_type(tag)
            operation.add_response_type(Type.from_type_list(tag.types), tag.text) if tag
          when "error_message", "response"
            operation.add_response(tag)
          when "summary"
            operation.summary = tag.text
          when "operation_id"
            operation.operation_id = tag.text
          when "extension"
            operation.add_extension(tag)
          when "example"
            if tag.name && !tag.name.empty?
              operation.response(tag.name).example = tag.text
            else
              operation.default_response.example = tag.text
            end
          end
        end

        operation.sort_parameters
      end
    end

    def initialize(path_item)
      @path_item      = path_item
      @summary        = nil
      @operation_id  = nil
      @description    = ""
      @parameters     = []
      @default_response = nil
      @responses = []
      @extensions = {}
    end

    def summary
      @summary || default_summary
    end

    def operation_id
      @operation_id || "#{api_group.resource}-#{ruby_method}"
    end

    def api_group
      path_item.api_group
    end

    def group
      api_group
    end

    def tags
      [api_group.resource].compact
    end

    def responses_by_status
      {}.tap do |hash|
        hash['default'] = default_response if @default_response || @responses.empty?
        responses.each do |response|
          hash[response.status] = response
        end
      end
    end

    def extended_attributes
      @extensions.tap do |h|
        h["x-api-resource"] = {
          "class" => api_group.class_name,
          "method" => ruby_method.to_s
        }
      end
    end

    ##
    # Example: [GET] /api/v2/ownerships
    # Example: [PUT] /api/v1/accounts/{account_id}
    def add_path_params_and_method(tag)
      method = tag.tag_name == "event" ? "POST" : tag.types.first
      if @path && @http_method
        SwaggerYard.log.warn 'multiple path/event tags not supported: ' \
          "ignored [#{method}] #{tag.text}"
        return
      end

      @path = tag.text
      @http_method = method

      parse_path_params(tag.text).each do |name|
        add_or_update_parameter Parameter.from_path_param(name)
      end
    end

    ##
    # Example: something_created_event
    def add_event_params_and_method(tag)
      if @path && @http_method
        SwaggerYard.log.warn 'multiple path/event tags not supported: ' \
          "ignored [#{tag.types&.first}] #{tag.text}"
        return
      end

      @path = tag.text
      @http_method = "POST"

      parse_path_params(tag.text).each do |name|
        add_or_update_parameter Parameter.from_path_param(name)
      end
    end

    ##
    # Example: [Array]     status            Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required, body)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Integer]   media[media_type_id]                          ID of the desired media type.
    def add_parameter(tag)
      param = Parameter.from_yard_tag(tag)
      add_or_update_parameter param if param
    end

    def add_or_update_parameter(parameter)
      if existing = @parameters.detect {|param| param.name == parameter.name }
        existing.description    = parameter.description unless parameter.from_path?
        existing.param_type     = parameter.param_type if parameter.from_path?
        existing.required     ||= parameter.required
        existing.allow_multiple = parameter.allow_multiple
      elsif parameter.param_type == 'body' && @parameters.detect {|param| param.param_type == 'body'}
        SwaggerYard.log.warn 'multiple body parameters invalid: ' \
          "ignored #{parameter.name} for #{@path_item.api_group.class_name}##{ruby_method}"
      else
        @parameters << parameter
      end
    end

    def default_response
      @default_response ||= Response.new.tap do |r|
        r.status = 'default'
      end
    end

    ##
    # Example:
    # @response_type [Ownership] the requested ownership
    def add_response_type(type, desc)
      default_response.type = type
      default_response.description = desc
    end

    def response(name)
      status = Integer(name)
      resp = responses.detect { |r| r.status == status }
      unless resp
        resp = Response.new
        resp.status = status
        responses << resp
      end
      resp
    end

    def add_response(tag)
      tag = SwaggerYard.requires_name(tag)
      return unless tag
      r = response(tag.name)
      r.description = tag.text if tag.text
      r.type = Type.from_type_list(Array(tag.types)) if tag.types
      r
    end

    def sort_parameters
      @parameters.sort_by! {|p| p.name}
    end

    ##
    # Example:
    # @extension x-internal: true
    def add_extension(tag)
      key, value = tag.text.split(":", 2).map(&:strip)

      unless key.start_with?("x-")
        SwaggerYard.log.warn("extension '#{tag.text}' must being with 'x-'")
      end

      @extensions[key] = value
    end

    def internal?
      extensions["x-internal"] == 'true'
    end

    private
    def parse_path_params(path)
      path.scan(/\{([^\}]+)\}/).flatten
    end

    def default_summary
      if SwaggerYard.config.default_summary_to_description
        description.split("\n\n").first || ""
      else
        ""
      end
    end
  end
end
