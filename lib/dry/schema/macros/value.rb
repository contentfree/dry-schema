# frozen_string_literal: true

require "dry/schema/path"
require "dry/schema/macros/dsl"

module Dry
  module Schema
    module Macros
      # A macro used for specifying predicates to be applied to values from a hash
      #
      # @api private
      class Value < DSL
        # @api private
        #
        def call(type_spec, *predicates, **opts, &block)
          set_type(type_spec)

          type = schema_dsl.types[name]

          trace.evaluate(*predicate_inferrer[type], *predicates, **opts)
          trace.append(new(chain: false).instance_exec(&block)) if block

          if trace.captures.empty?
            raise ArgumentError, "wrong number of arguments (given 0, expected at least 1)"
          end

          self
        end

        # @api private
        def array_type?(type)
          primitive_inferrer[type].eql?([::Array])
        end

        # @api private
        def hash_type?(type)
          primitive_inferrer[type].eql?([::Hash])
        end

        # @api private
        def maybe_type?(type)
          type.meta[:maybe].equal?(true)
        end

        # @api private
        def build_array_type(array_type, member)
          if array_type.respond_to?(:of)
            array_type.of(member)
          else
            raise ArgumentError, <<~ERROR.split("\n").join(" ")
              Cannot define schema for a nominal array type.
              Array types must be instances of Dry::Types::Array,
              usually constructed with Types::Constructor(Array) { ... } or
              Dry::Types['array'].constructor { ... }
            ERROR
          end
        end

        # @api private
        def import_steps(schema)
          schema_dsl.steps.import_callbacks(Path[[*path, name]], schema.steps)
        end

        # @api private
        def respond_to_missing?(meth, include_private = false)
          super || meth.to_s.end_with?(QUESTION_MARK)
        end

        private

        # @api private
        def method_missing(meth, *args, &block)
          if meth.to_s.end_with?(QUESTION_MARK)
            trace.__send__(meth, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
