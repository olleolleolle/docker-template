# Frozen-string-literal: true
# Copyright: 2015 Jordon Bedwell - Apache v2.0 License
# Encoding: utf-8

require "optparse"

module Docker
  module Template
    class Interface
      include Hooks::Methods

      register_hook_point :parse
      def initialize(zero, argv = [])
        @zero = zero
        @raw_argv = argv
        parse!
      end

      #

      def run
        Parser.new(@raw_repos, @argv).parse.map do |repo|
          repo.build
        end
      end

      #

      def parse!
        @argv = {}
        parse = OptParse.new do |parser|
          run_hooks :parse, parser
          banner_bin = self.class.bin?(@zero) ? "docker template" : "docker-template"
          parser.banner = "Usage: #{banner_bin} [repos] [flags]"
        end

        @raw_repos = Set.new
        @raw_repos.merge(parse.parse!(@raw_argv.dup))
        @raw_repos.freeze
        @argv.freeze
      end

      # Determine whether we are the Docker bin so that we can transform
      # based on that... for example we will pass on commands to `docker` if
      # we are running as the `docker` binary in place of `docker`.

      private
      def self.bin?(bin)
        !bin ? false : File.basename(bin.to_s) == "docker"
      end

      # Discover the Docker bin using Ruby.  This is a highly unoptimized
      # method and needs to be reworked because it's pretty trashy shit and
      # it's just flat out ugly to look at, make it better than it is.

      private
      def self.discover
        rtn = bins.find do |path|
          path.basename.fnmatch?("docker") && path.executable_real?
        end

        if rtn
          rtn.to_s
        end
      end

      #

      private
      def self.start(zero)
        return new(zero, ARGV[1..-1]).run if ARGV[0] == "template" && bin?(zero)
        return new(zero, ARGV).run unless bin?(zero)

        exe = discover
        exec exe.to_s, *ARGV if exe
        abort "No Docker."
      rescue Error::StandardError => error_
        $stderr.puts Simple::Ansi.red(error_.message)
        $stderr.puts Simple::Ansi.red("Aborting your build. Bye and good luck.")
        exit error_.respond_to?(:status) ? error_.status.to_i : 1
      end

      #

      private
      def self.bins
        ENV["PATH"].split(":").each_with_object(Set.new) do |val, array|
          array.merge(Pathname.new(val).children) rescue next
        end
      end
    end
  end
end
