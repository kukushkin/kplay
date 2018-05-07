# frozen_string_literal: true

module Kplay
  module Minikube
    # Returns the host folder, path on host.
    #
    # Host folder is the single folder Minikube mounts by default into the VM.
    # Usually it's /home or /Users.
    #
    def self.hostfolder_host
      case Kplay.host_os
      when :linux
        '/home/'
      when :macosx
        '/Users/'
      else
        raise 'Cannot identify mounted host folder, unknown OS'
      end
    end

    # Returns the host folder mount point, path on minikube VM
    #
    def self.hostfolder_vm
      case Kplay.host_os
      when :linux
        '/hosthome/'
      when :macosx
        '/Users/'
      else
        raise 'Cannot identify mounted host folder, unknown OS'
      end
    end

    # Given the path on host returns the corresponding path in VM.
    # Raises an error if the folder on host is not mounted.
    #
    # @param path_host [String] path to a folder on a host machine
    # @return [String] corresponding path in VM
    #
    def self.host_path_in_vm(path_host)
      unless path_host.to_s.start_with?(hostfolder_host.to_s)
        raise ArgumentError, "Failed to find mount point for: '#{path_host}', parent is not mounted"
      end
      Pathname.new(path_host.to_s.sub(hostfolder_host.to_s, hostfolder_vm.to_s))
    end
  end # module Minikube
end # module Kplay
