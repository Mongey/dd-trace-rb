require 'ddtrace/configuration/base'

require 'ddtrace/ext/analytics'
require 'ddtrace/ext/distributed'
require 'ddtrace/ext/runtime'
require 'ddtrace/ext/sampling'

require 'ddtrace/logger'

module Datadog
  module Configuration
    # Global configuration settings for the trace library.
    class Settings
      include Base

      #
      # Configuration options
      #
      option :analytics_enabled do |o|
        o.default { env_to_bool(Ext::Analytics::ENV_TRACE_ANALYTICS_ENABLED, nil) }
        o.lazy
      end

      option :report_hostname do |o|
        o.default { env_to_bool(Ext::NET::ENV_REPORT_HOSTNAME, false) }
        o.lazy
      end

      option :runtime_metrics_enabled do |o|
        o.default { env_to_bool(Ext::Runtime::Metrics::ENV_ENABLED, false) }
        o.lazy
      end

      settings :distributed_tracing do
        option :propagation_extract_style do |o|
          o.default do
            # Look for all headers by default
            env_to_list(Ext::DistributedTracing::PROPAGATION_EXTRACT_STYLE_ENV,
                        [Ext::DistributedTracing::PROPAGATION_STYLE_DATADOG,
                         Ext::DistributedTracing::PROPAGATION_STYLE_B3,
                         Ext::DistributedTracing::PROPAGATION_STYLE_B3_SINGLE_HEADER])
          end

          o.lazy
        end

        option :propagation_inject_style do |o|
          o.default do
            # Only inject Datadog headers by default
            env_to_list(Ext::DistributedTracing::PROPAGATION_INJECT_STYLE_ENV,
                        [Ext::DistributedTracing::PROPAGATION_STYLE_DATADOG])
          end

          o.lazy
        end
      end

      settings :sampling do
        option :default_rate do |o|
          o.default { env_to_float(Ext::Sampling::ENV_SAMPLE_RATE, nil) }
          o.lazy
        end

        option :rate_limit do |o|
          o.default { env_to_float(Ext::Sampling::ENV_RATE_LIMIT, 100) }
          o.lazy
        end
      end

      settings :diagnostics do
        settings :health_metrics do |o|
          option :enabled do |o|
            o.default { env_to_bool(Datadog::Ext::Diagnostics::Health::Metrics::ENV_ENABLED, false) }
            o.lazy
          end
        end
      end

      # Backwards compatibility for configuring tracer e.g. `c.tracer debug: true`
      def tracer(options = nil)
        Datadog.tracer = options[:instance] if options && options.key?(:instance)
        tracer = Datadog.tracer

        tracer.tap do |t|
          unless options.nil?
            t.configure(options)
            Datadog::Logger.log = options[:log] if options[:log]
            t.set_tags(options[:tags]) if options[:tags]
            t.set_tags(env: options[:env]) if options[:env]
            Datadog::Logger.debug_logging = options.fetch(:debug, false)
          end
        end
      end

      def runtime_metrics(options = nil)
        runtime_metrics = Datadog.tracer.writer.runtime_metrics
        return runtime_metrics if options.nil?

        runtime_metrics.configure(options)
      end
    end
  end
end
