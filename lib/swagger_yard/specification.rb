module SwaggerYard
  class Specification
    attr_accessor :authorizations

    def initialize(controller_path = SwaggerYard.config.controller_path,
                   model_path = SwaggerYard.config.model_path,
                   webhook_path = SwaggerYard.config.webhook_path
                  )
      @model_paths = [*model_path].compact
      @controller_paths = [*controller_path].compact
      @webhook_paths = [*webhook_path].compact

      @resource_to_file_path = {}
      @authorizations = []
    end

    def path_objects(for_webhooks: false)
      groups = for_webhooks ? webhook_groups : path_groups
      groups.map(&:paths).reduce(Paths.new, :merge).tap do |paths|
        warn_duplicate_operations(paths)
      end
    end

    # Resources
    def tag_objects
      path_groups.map(&:tag) + webhook_groups.map(&:tag)
    end

    def tag_groups
      return if path_groups.none?(&:tag_group)

      groups = {}
      path_groups.each do |group|
        groups[group.tag_group] ||= []
        groups[group.tag_group] << group.resource
      end

      groups.map do |name, tags|
        {
          name: name,
          tags: tags.uniq
        }
      end
    end

    def model_objects
      Hash[models.map {|m| [m.id, m]}]
    end

    def property_objects
      Hash[properties.map {|m| [m.id, m]}]
    end

    def security_objects
      path_groups # triggers controller parsing in case it did not happen before
      Hash[authorizations.map {|auth| [auth.id, auth]}]
    end

    private
    def models
      @models ||= parse_models
    end

    def properties
      @properties ||= parse_properties
    end

    def path_groups
      @path_groups ||= parse_controllers.select { |group| group.path_items.present? }
    end

    def webhook_groups
      @webhook_groups ||= parse_webhook_groups.select { |webhook_group| webhook_group.path_items.present? }
    end

    def parse_models
      @model_paths.map do |model_path|
        Dir[model_path.to_s].map do |file_path|
          SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
            Model.from_yard_object(obj)
          end
        end
      end.flatten.compact.select(&:valid?)
    end

    def parse_properties
      @model_paths.map do |model_path|
        Dir[model_path.to_s].map do |file_path|
          SwaggerYard.yard_constant_objects_from_file(file_path).map do |obj|
            Property.from_constant(obj)
          end
        end
      end.flatten.compact
    end

    def parse_controllers
      @controller_paths.map do |controller_path|
        Dir[controller_path.to_s].map do |file_path|
          SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
            obj.tags.select {|t| t.tag_name == "authorization"}.each do |t|
              @authorizations << Authorization.from_yard_object(t)
            end
            ApiGroup.from_yard_object(obj, is_paths_object: true)
          end
        end
      end.flatten.select(&:valid?)
    end

    def parse_webhook_groups
      @webhook_paths.map do |webhook_path|
        Dir[webhook_path.to_s].map do |file_path|
          SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
            obj.tags.select {|t| t.tag_name == "authorization"}.each do |t|
              @authorizations << Authorization.from_yard_object(t)
            end
            ApiGroup.from_yard_object(obj, is_paths_object: false)
          end
        end
      end.flatten.select(&:valid?)
    end

    def warn_duplicate_operations(paths)
      operation_ids = []
      paths.path_items.each do |_, pi|
        pi.operations.each do |_, op|
          if operation_ids.include?(op.operation_id)
            SwaggerYard.log.warn("duplicate operation #{op.operation_id}")
            next
          end
          operation_ids << op.operation_id
        end
      end
    end
  end
end
