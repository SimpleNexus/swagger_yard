module SwaggerYard
  class ApiGroup
    attr_accessor :description, :resource
    attr_reader :path_items, :authorizations, :class_name, :tag_group, :is_paths_object

    def self.from_yard_object(yard_object, is_paths_object:)
      new(is_paths_object: is_paths_object).add_yard_object(yard_object)
    end

    def initialize(is_paths_object:)
      @resource       = nil
      @path_items     = {}
      @authorizations = {}
      @is_paths_object = is_paths_object
    end

    def valid?
      !@resource.nil?
    end

    def paths
      Paths.new(path_items)
    end

    def tag
      @tag ||= Tag.new(resource, description)
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
        add_path_item(yard_object)
      end
      self
    end

    def add_info(yard_object)
      @description = yard_object.docstring
      @class_name  = yard_object.path

      if tag = yard_object.tags.detect {|t| t.tag_name == is_paths_object ? "resource" : "webhook_group"}
        @resource = tag.text
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

    def add_path_item(yard_object)
      path = path_from_yard_object(yard_object)
      operation = Operation.from_yard_object(yard_object, self, is_paths_object: is_paths_object)

      return if path.nil? || (operation.internal? && SwaggerYard.config.ignore_internal)

      path_item = (path_items[path] ||= PathItem.new(self))
      path_item.add_operation(yard_object, is_paths_object: is_paths_object)
      path
    end

    def path_from_yard_object(yard_object)
      if !is_paths_object
        yard_object.tags.detect {|t| t.tag_name == "event"}&.text
      elsif tag = yard_object.tags.detect {|t| t.tag_name == "path"}
        tag.text
      elsif fn = SwaggerYard.config.path_discovery_function
        begin
          method, path = fn[yard_object]
          yard_object.add_tag YARD::Tags::Tag.new("path", path, [method]) if path
          path
        rescue => e
          SwaggerYard.log.warn e.message
          nil
        end
      end
    end
  end
end
