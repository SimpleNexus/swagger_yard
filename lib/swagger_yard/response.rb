module SwaggerYard
  class Response
    include Example
    attr_accessor :status, :description, :type
  end
end
