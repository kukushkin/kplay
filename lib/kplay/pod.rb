# frozen_string_literal: true
require 'yaml'
require 'tempfile'

module Kplay
  #
  # Pod represents a pod associated with a folder on a host machine
  #
  class Pod
    DEFAULT_SHM_VOLUME_NAME = "pod-shm-volume"
    DEFAULT_SHM_VOLUME_PATH = "/dev/shm"

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
      c = {
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
              'env' => [
                # { 'name' => ..., 'value' => ... }
              ],
              'volumeMounts' => [
                { 'mountPath' => config[:mount_path], 'name' => volume_name },
                { 'mountPath' => DEFAULT_SHM_VOLUME_PATH, 'name' => DEFAULT_SHM_VOLUME_NAME },
                # <-- ssh forwarding socket should be mounted a CONTAINER here
              ]
            }
          ],
          'volumes' => [
            {
              'name' => volume_name,
              'hostPath' => { 'path' => path_vm.to_s }
            },
            {
              'name' => DEFAULT_SHM_VOLUME_NAME,
              'emptyDir' => {
                'medium' => 'Memory',
                'sizeLimit' => config[:shm_size]
              }
            }
            # <-- ssh forwarding socket in VM mounted here
          ]
        }
      }
      # add custom volumes
      config[:volumes].each_with_index do |volume_def, i|
        v_from, v_to = volume_def.split(':')
        v_from = Kplay::Minikube.host_path_in_vm(Pathname.new(v_from).expand_path)
        v_to   = Pathname.new(v_to) # do not expand path locally
        name = 'volume-' + i.to_s
        c['spec']['containers'].first['volumeMounts'] <<
          { 'name' => name, 'mountPath' => v_to.to_s }
        c['spec']['volumes'] <<
          { 'name' => name, 'hostPath' => { 'path' => v_from.to_s } }
      end
      c
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
        ['kubectl', 'delete', 'pod', name, "--grace-period=#{config[:stop_grace_period]}"],
        echo: options[:verbose]
      )
    end

    # Runs a shell session inside the pod
    #
    def shell
      Kplay.sh(
        ['kubectl', 'exec', '-ti', name, '--', config[:shell], *config[:shell_args]],
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
