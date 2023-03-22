# SwaggerYard Changelog #

## 1.1.1 -- 10-28-2020 ##

- Add `include_private` and the ability to mark action methods as not documented - #67, thanks Daniel Areiza

## 1.1.0 -- 10-27-2020 ##

- Require Ruby 2.5.0 or greater (drop Ruby 1.9 support) - #69, thanks Stef Schenkelaars
- Add `enum<{CONSTANT}>` support - #70, thanks Stef Schenkelaars

## 1.0.4 -- 05-20-2020 ##

- Add `@additional_properties` tag
- Add union `(A|B)` and intersection `(A&B)` types
- Preserve uris registered as external schemas

## 1.0.3 -- 04-22-2020 ##

* PR #66 -- Add @!model directive, thanks Quentin Wentzler

## 1.0.2 -- 04-02-2019 ##

* PR #58 -- Bugfix: anchored match array or object

## 1.0.1 -- 24-07-2018 ##

* PR #57 -- Properties on model methods

- Allow `@property` tags to exist in comment blocks above model methods in addition to the class comment block.

## 1.0.0 -- 28-06-2018 ##

* PR #56 -- Examples

- Example data can be defined at the response, model, or property level and that data will be included in the swagger or openapi document per the [specification](https://swagger.io/docs/specification/adding-examples/).

* PR #55 -- OpenAPI 3 support

- Breaking release! Removed unused and deprecated configuration properties (`reload`, `enabled`, `swagger_spec_base_path`, `api_path`) and tags (`@response_path`).
- SwaggerYard now supports the OpenAPI 3 format. To generate OpenAPI 3 formatted json with your existing `swagger_yard` and `swagger_yard-rails` apps, simply add the `openapi_version` or change the `swagger_version` config property to be `'3.0.0'`.
      SwaggerYard.configure do |config|
	    config.openapi_version = '3.0.0'
	  end
- Add `@response` tag as preferred tag for controller actions to specify alternate responses (previously called `@error_message`).
- Internal object model refactor (rename ResourceListing -> Specification, ApiDeclaration -> ApiGroup, Api -> PathItem, introduced Tag, Paths and Response models)
- Moved all internal object model `#to_h` methods to SwaggerYard::Swagger so that we can support multiple formats
- Support OpenAPI security schemes (http instead of basic, support schemes from RFC7235)

## 0.4.4 -- 25-06-2018 ##

* PR #54 -- Inherits improvement + Validation fixes

## 0.4.3 -- 20-05-2018 ##

* PR #53 -- Bugfix: Handle both orders of parameter/property tags

## 0.4.2 -- 06-04-2018 ##

* PR #52 -- Bugfix: don't document models without a @model tag

## 0.4.1 -- 06-04-2018 ##

* PR #51 -- model doc improvements
  * Populate the model description from the class docstring
  * Allow model name to be omitted, using the class name as the model name
  * Allow inherits to use an arbitrary type (thus allowing inheriting from external schema)


## 0.4.0 -- 05-04-2018 ##

* PR #48 (thanks Brad Lindsay)
  * Sort the tag list in the tags section of the swagger document
* PR #49
  * Fixes to make swagger yard output more swagger-validation-friendly
* PR #50
  * Enable references to external schema documents. See README for details.

## 0.3.7 -- 23-11-2016 ##

* PR #40 (thanks Nick Sieger and Brad Lindsay)
  * Add the `parslet` gem for type parsing inline definitions of arrays, enums, objects, etc.
  * making it possible to nest object definitions, defining their properties and additional properties at the same time / inline
  * updating README with descriptions of the `object` definition and nesting syntax.
* Also, bumping Ruby version to 2.3.3
* PR #43 (thanks Ole Michaelis)
  * Add support for configuring OAuth security definitions

## 0.3.6 -- 26-02-2016 ##

* PR #38 (thanks OpenGov and Tim Rodriguez)
  * Add polymorphism support in models
  * Add nested object support (map/dictionary functionality)
  * Proper port support in `api_base_path`
  * Support Arrays and Pathnames in model & controller path configs

## 0.3.5 -- 29-01-2016 ##

* Ensure controller and action attributes are strings

## 0.3.4 -- 29-01-2016 ##

* Annotate operation with `x-controller` and `x-action` attributes

## 0.3.3 -- 25-01-2016 ##

* Need to mangle type names for consistency

## 0.3.2 -- 22-01-2016 ##

* Ensure only one parameter object for each declared name
* Mangle model names such that only alphanumeric and '_' are allowed
* Repository moved under `livingsocial` organization.

## 0.3.1 ##

* Use hashing functionality of YARD registry to avoid re-parsing files that
  haven't changed, improving performance for larger codebases.
* Deprecate `@resource_path` and remove `@status_code`
* Add more types and options (nullable, JSON Schema formats, regexes, uuid)

## 0.3.0 ##

* Add `config.path_discovery_function` to be able to hook in logic from
  swagger_yard-rails to compute paths from the router
* Allow `@resource_path` to be omitted in a controller class docstring.
  `@resource` is required in order to indicate that a controller is swaggered.
* Remove `@notes` tag. There is no convenient place for notes to be mapped to a
  swagger spec other than to be part of the API's description.
* Remove `@parameter_list` tag in favor of new `enum<val1,val2>` type. Parameter
  list usage was cumbersome and not well documented. This also enabled removal
  of the Parameter class `allowable_values` option, which was no longer used.
* Remove implicit, undocumented `format_type` parameter. If you still need a
  format (or `format_type`) parameter, use the new `enum` type. Example:

    ```
	# @path /hello.{format}
    # @parameter format [enum<json,xml>] Format of the response. One of JSON or XML.
    ```

* Deprecate `config.swagger_spec_base_path` and `config.api_path`. Not used anywhere.

## 0.2.0 -- 20-10-2015 ##

* Support for Swagger's Spec v2

    *Nick Sieger <@nicksieger>*

* Remove support for Spec v1

    *Tony Pitale <@tpitale>*

## 0.1.0 -- 15-10-2015 ##

* !REMOVE RAILS ENGINE AND UI!

    *Tony Pitale <@tpitale>*

## 0.0.7 ##

*   Allow deeply nested model objects

    *Peter Doree*

*   Adds support for Model and $ref
*   Add doc update for using Model
*   Fix failure when `app/controllers` had `module`s in it
*   Add specs

    *Tony Pitale*
