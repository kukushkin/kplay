# frozen_string_literal
require 'thor'

module Kplay
  class CLI < Thor
    using Rainbow

    class_option :verbose, type: :boolean, aliases: :v, default: false

    desc 'info', 'Displays environment info'
    def info
      print 'Checking requirements... '
      Kplay.assert_requirements!
      puts 'OK'.green

      path = Dir.pwd
      pod  = Kplay::Pod.new(path)
      puts "     name: #{pod.name}"
      puts "host path: #{pod.path_host}"
      puts "  vm path: #{pod.path_vm}"
      puts
    end

    desc 'config', 'Displays local configuration'
    def config
      print 'Global config file: '
      puts Kplay::Config.global.path.to_s.yellow
      puts
      config = Kplay::Config.local
      puts config.to_h.to_yaml
    end

    desc 'status', 'Displays the cluster and container (pod) status'
    def status
      Kplay.assert_requirements!
      Kplay.sh ['minikube', 'status']
      pod = Kplay::Pod.new(Dir.pwd)
      Kplay.sh ['kubectl', 'get', 'pods', pod.name] rescue nil
    end

    desc 'start', 'Starts a container (pod) with the local folder mounted inside'
    option :image, aliases: :i, desc: 'Image to use'
    def start
      Kplay.assert_requirements!
      pod = Kplay::Pod.new(Dir.pwd, Kplay::Config.local, options)
      pod.start!
    end

    desc 'stop', 'Stops the container (pod) associated with the local folder'
    def stop
      Kplay.assert_requirements!
      pod = Kplay::Pod.new(Dir.pwd, Kplay::Config.local, options)
      pod.stop!
    end

    desc 'open', 'Opens a shell session into the container'
    def open
      Kplay.assert_requirements!
      pod = Kplay::Pod.new(Dir.pwd, Kplay::Config.local, options)
      pod.shell
    end

    desc 'play', '(default) Starts the container and opens a shell session into it'
    option :image, aliases: :i, desc: 'Image to use'
    def play
      start
      open
      stop
    end
    default_task :play
  end # class CLI
end # module Kplay
