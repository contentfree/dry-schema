# frozen_string_literal: true

require 'dry/core/cache'

module Dry
  module Schema
    # PrimitiveInferrer is used internally by `Macros::Filled`
    # for inferring a list of possible primitives that a given
    # type can handle.
    #
    # @api private
    class PrimitiveInferrer
      extend Dry::Core::Cache

      # Compiler reduces type AST into a list of primitives
      #
      # @api private
      class Compiler
        # @api private
        def visit(node)
          meth, rest = node
          public_send(:"visit_#{meth}", rest)
        end

        # @api private
        def visit_nominal(node)
          type, _ = node
          type
        end

        # @api private
        def visit_hash(_)
          Hash
        end

        # @api private
        def visit_array(_)
          Array
        end

        # @api private
        def visit_lax(node)
          visit(node)
        end

        # @api private
        def visit_constructor(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_enum(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_sum(node)
          left, right = node

          [visit(left), visit(right)].flatten(1)
        end

        # @api private
        def visit_constrained(node)
          other, * = node
          visit(other)
        end

        # @api private
        def visit_any(_)
          Object
        end
      end

      # @return [Compiler]
      # @api private
      attr_reader :compiler

      # @api private
      def initialize
        @compiler = Compiler.new
      end

      # Infer predicate identifier from the provided type
      #
      # @return [Symbol]
      #
      # @api private
      def [](type)
        self.class.fetch_or_store(type.hash) do
          Array(compiler.visit(type.to_ast)).freeze
        end
      end
    end
  end
end
