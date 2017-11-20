require "trailblazer/circuit"

# TODO: move to separate gem.
require "trailblazer/option"
require "trailblazer/context"
require "trailblazer/container_chain"

module Trailblazer
  class Activity

    require "trailblazer/activity/version"
    require "trailblazer/activity/subprocess"

    require "trailblazer/activity/wrap"
    require "trailblazer/wrap/variable_mapping"
    require "trailblazer/wrap/call_task"
    require "trailblazer/wrap/trace"
    require "trailblazer/wrap/inject"
    require "trailblazer/wrap/runner"

    require "trailblazer/activity/trace"
    require "trailblazer/activity/present"


    require "trailblazer/activity/magnetic" # the "magnetic" DSL
    require "trailblazer/activity/schema/sequence"

    require "trailblazer/activity/process"


    def self.inherited(inheriter)
      inheriter.initialize_activity_dsl!
      inheriter.recompile_process!
    end
    # called in subclasses
    def self.initialize_activity_dsl!
      @builder = Magnetic::Path::Builder.new({}, Normalizer)
    end

    def self.recompile_process!
      @process, @outputs = Magnetic::Path::Builder.finalize( @builder.instance_variable_get(:@adds) )
    end

    def self.outputs
      @outputs
    end

    def self.call(args, circuit_options={})
      @process.( args, circuit_options.merge( exec_context: new ) ) # DISCUSS: do we even need that?
    end

    #- DSL part

    def self.build(&block)
      Class.new(Activity, &block)
    end

    # DSL part
    # delegate as much as possible to Builder
    # let us process options and e.g. do :id
    class << self
      extend Forwardable
      def_delegators :@builder, :Output, :Path, :task
    end

    class Normalizer
      def self.call(task, options)
        options =
          {
            plus_poles: initial_plus_poles,
            id:         task.inspect, # TODO.
          }.merge(options)

        return task, options
      end

      def self.initial_plus_poles
        Magnetic::DSL::PlusPoles.new.merge(
          Magnetic.Output(Circuit::Right, :success) => nil
        ).freeze
      end
    end


    class Introspection
      # @param activity Activity
      def initialize(activity)
        @activity = activity
        @graph    = activity.graph
        @circuit  = activity.circuit
      end

      # Find the node that wraps `task` or return nil.
      def [](task)
        @graph.find_all { |node| node[:_wrapped] == task  }.first
      end
    end
  end
end
