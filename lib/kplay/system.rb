
# frozen_string_literal: true
require 'open3'

module Kplay
  #
  # Common system extensions
  #
  module System
    def self.included(base)
      base.send :extend, ClassMethods
    end

    # Class level methods
    module ClassMethods
      DEFAULT_SH_OPTS = {
        echo: true,
        output: true,
        tty: false
      }.freeze

      # Executes a shell command on the host
      #
      # @param cmd [String] command to execute
      # @param opts [Hash]
      # @option opts [true,false] :echo echo command to stdout (default: true)
      # @option opts [true,false] :output display (true) or suppress (false) commands output (default: true)
      # @option opts [true,false] :tty attach a TTY (stdin is preserved and output is never suppressed), (default: false)
      #
      def sh(cmd, opts = {})
        opts = DEFAULT_SH_OPTS.merge(opts)
        cmd = [cmd] if cmd.is_a?(String)
        puts cmd.join(' ') if opts[:echo]
        exit_status = nil
        if opts[:tty]
          system(*cmd)
          exit_status = 0
        else
          out, status = Open3.capture2(*cmd)
          puts out if opts[:output]
          exit_status = status.exitstatus
        end
        raise "Failed to execute '#{cmd.join(' ')}' (#{status.exitstatus})" unless exit_status == 0
      end

      # Checks if program with given name is present. Raises an error if the program is not found.
      #
      def assert_program_presence!(name)
        sh(['which', name], echo: false, output: false)
      rescue
        raise "Failed to find required program: #{name}"
      end

      # Outputs a string to STDOUT without adding a line break
      #
      # @param text [String]
      #
      def print(text)
        Kernel.print(text)
        $stdout.flush
      end

      # Returns the OS identifier
      #
      # @return [Symbol] :linux, :macosx or :unknown
      #
      def host_os
        name = `uname`.split(' ').first.downcase.to_sym
        case name
        when :linux
          :linux
        when :darwin
          :macosx
        else
          :unknown
        end
      end
    end # module ClassMethods
  end # module System
end # module Kplay
