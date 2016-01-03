# Frozen-string-literal: true
# Copyright: 2015 Jordon Bedwell - Apache v2.0 License
# Encoding: utf-8

module Docker
  module Template
    class Stream
      def initialize
        @lines = {}
      end

      #

      def log(part)
        stream = JSON.parse(part)
        return progress_bar(stream) if stream.any_keys?("progress", "progressDetail")
        return $stdout.puts stream["status"] || stream["stream"] if stream.any_keys?("status", "stream")
        return progress_error(stream) if stream.any_keys?("errorDetail", "error")

        warn Simple::Ansi.red("Unhandled stream message")
        $stderr.puts Simple::Ansi.red("Please file a bug ticket.")
        $stdout.puts part
      end

      #

      def progress_error(stream)
        abort Simple::Ansi.red((stream["error"] || stream["errorDetail"]["message"]).capitalize)
      end

      #

      private
      def progress_bar(stream)
        id = stream["id"]
        unless id
          return
        end

        before, diff = progress_diff(id)
        $stdout.print before if before
        str = stream["progress"] || stream["status"]
        str = "#{id}: #{str}\r"

        $stdout.print(Simple::Ansi.jump(str, diff))
      end

      #

      private
      def progress_diff(id)
        if @lines.key?(id)
          return nil, @lines.size - @lines[id]
        end

        @lines[id] = @lines.size
        before = "\n" unless @lines.one?
        return before, 0
      end
    end
  end
end
