# frozen_string_literal: true
require 'yaml'
require 'tempfile'

module Kplay
  #
  # Pod represents a pod associated with a folder on a host machine
  #
  class Pod
    attr_reader :name, :config, :volume_name, :path_host, :path_vm, :mount_path, :options

    # Creates a Pod from a path on host
    #
    # @param path_host [String]
    # @param config [Config] local pod configuration options
    # @param options [Hash] command execution options
    #
    def initialize(path_host, config = nil, options = {})
      @path_host = path_host
      @path_vm = Kplay::Minikube.host_path_in_vm(path_host)
      @name = File.basename(path_host)
      @config = config ? config : Kplay::Config.global
      @config.expand_templates!(
        name: name,
        path_host: path_host,
        path_vm: path_vm
      )
      @options = options
      @volume_name = name + '-volume'
    end

    # Kubernetes configuration to run this pod
    #
    # @return [Hash]
    #
    def configuration
      host_aliases = config[:etc_hosts].map do |host|
        ip, *hostnames = host.strip.split(' ')
        { 'ip' => ip, 'hostnames' => hostnames }
      end
      {
        'apiVersion' => 'v1',
        'kind' => 'Pod',
        'metadata' => { 'name' => name },
        'spec' => {
          'hostAliases' => host_aliases,
          'containers' => [
            {
              'name' => name,
              'image' => options[:image] || config[:image],
              'imagePullPolicy' => 'IfNotPresent',
              'volumeMounts' => [
                { 'mountPath' => config[:mount_path], 'name' => volume_name }
              ]
            }
          ],
          'volumes' => [
            {
              'name' => volume_name,
              'hostPath' => { 'path' => path_host }
            }
          ]
        }
      }
    end

    # Returns Kubernetes pod configuration in YAML
    #
    def configuration_yaml
      configuration.to_yaml
    end

    # Runs the pod in Kubernetes cluster
    #
    def start!
      with_configuration_file do |conf_file|
        Kplay.sh ['kubectl', 'apply', '-f', conf_file.path], echo: options[:verbose]
      end
      sleep 1
    end

    # Stops the pod
    #
    def stop!
      Kplay.sh(
        ['kubectl', 'delete', 'pod', name, "--grace-period=#{config[:stop_grace_period]}", '--force'],
        echo: options[:verbose]
      )
    end

    # Runs a shell session inside the pod
    #
    def shell
      Kplay.sh(
        ['kubectl', 'exec', name, '-ti', config[:shell], '--', *config[:shell_args]],
        tty: true,
        echo: options[:verbose]
      )
    end

    # Creates a temporary configuration file and returns it
    #
    # @return [Tempfile]
    #
    def temp_configuration_file
      @temp_configuration_file ||= begin
        tempfile = Tempfile.new("kplay-#{name}")
        tempfile.write(configuration_yaml)
        tempfile.close
        tempfile
      end
    end

    # Creates a temporary configuration file for the pod, yields it to the given block
    # and then deletes it.
    #
    #
    def with_configuration_file(&_block)
      yield temp_configuration_file
    ensure
      temp_configuration_file.unlink
      @temp_configuration_file = nil
    end
  end # class Pod
end # module Kplay
