# frozen_string_literal: true
require 'rainbow/refinement'

require 'kplay/version'
require_relative 'kplay/system'
require_relative 'kplay/cli'
require_relative 'kplay/minikube'
require_relative 'kplay/config'
require_relative 'kplay/pod'
require_relative 'kplay/registry'

module Kplay
  include System

  DEFAULT_DATA_FOLDER = '~/.kplay'

  #
  # Checks if requirements are satisfied
  #
  def self.assert_requirements!
    assert_program_presence!('minikube')
    assert_program_presence!('kubectl')
  end

  # Returns path to data folder or its subfolders/files
  #
  def self.data_path(*paths)
    Pathname.new(DEFAULT_DATA_FOLDER).join(*paths).expand_path
  end

  # Install data folder
  #
  def self.install_paths
    sh ['install', '-p', data_path]
  end
end # module Kplay
