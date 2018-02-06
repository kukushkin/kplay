# frozen_string_literal: true

module Kplay
  #
  # Represents the registry of started pods
  #
  module Registry
    # Registers a pod started by given process
    #
    def self.register(pod_name, pid)
    end

    # Unregisters a pod started by given process
    #
    def self.unregister(pod_name, pid)
    end

    # Unregisters a pod for all processes
    #
    def self.unregister_all(pod_name)
    end

    # Returns true if the pod is registered for any process
    #
    def self.registered?(pod_name)
    end

    private # -ish

    def self.storage_path

    end
  end # module Registry
end # module Kplay
