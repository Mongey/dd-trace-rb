require 'ddtrace/tracer'

module Datadog
  module Configuration
    # Global components for the trace library.
    module Components
      attr_writer \
        :health_metrics,
        :tracer

      def tracer
        @tracer ||= Tracer.new
      end

      def health_metrics
        @health_metrics ||= Datadog::Diagnostics::Health::Metrics.new
      end

      def runtime_metrics
        tracer.writer.runtime_metrics
      end
    end
  end
end
