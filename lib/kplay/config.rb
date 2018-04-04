# frozen_string_literal: true
require 'yaml'

module Kplay
  #
  # Represents the global or local configuration
  #
  class Config
    GLOBAL_CONFIG_FILENAME = 'config'
    GLOBAL_DEFAULTS = {
      'image' => 'dev',
      'mount_path' => '/${name}',
      'shell' => '/bin/bash',
      'shell_args' => ['-c', 'cd /${name}; exec "${SHELL:-sh}"'],
      'stop_grace_period' => 5,
      'etc_hosts' => [] # <ip> <alias1> [<alias2> ...]
    }.freeze

    attr_reader :path, :data

    def initialize(data = {}, path = nil)
      @path = path ? Pathname.new(path).expand_path : nil
      @data = data.dup
      @extra_data = YAML.load(File.read(path)) if path && File.exist?(path)
      @data = @data.merge(@extra_data) if @extra_data
    end

    def [](key)
      value = data[key.to_s]
      value = self.class.new(value) if value.is_a?(Hash)
      value
    end

    def to_h
      data.dup
    end

    # Expands templates in the values of the current config.
    #
    def expand_templates!(vars)
      self.class.expand_templates!(@data, vars)
    end

    # In-place expansion of templates.
    # Templates found in values are substituted with given vars
    #
    def self.expand_templates!(hash, vars)
      hash.keys.each do |key|
        case hash[key]
        when String
          hash[key] = expand_template(hash[key], vars)
        when Array
          hash[key] = hash[key].map { |t| expand_template(t, vars) }
        when Hash
          expand_templates!(hash[key], vars)
        end
      end
    end

    # Expand templates in given string value.
    #
    # Example:
    #   "${name}" -> "my-pod"
    #
    # @param text [String]
    # @param vars [Hash]
    #
    def self.expand_template(text, vars)
      vars.keys.reduce(text) do |t, var_name|
        t.gsub("${#{var_name}}", vars[var_name].to_s)
      end
    end

    def self.global
      new(GLOBAL_DEFAULTS.dup, Kplay.data_path(GLOBAL_CONFIG_FILENAME))
    end

    def self.local
      new(global.data, Pathname.pwd.join('.kplay'))
    end
  end # class Config
end # module Kplay
