require 'erb'
require 'yaml'
require 'active_support/core_ext/hash/deep_merge'
require 'pathname'

class ChorusConfig
  attr_accessor :config

  def initialize(root_dir=nil)
    set_root_dir(root_dir)
    app_config = {}
    app_config = YAML.load_file(config_file_path) if File.exists?(config_file_path)
    defaults = YAML.load_file(File.join(@root_dir, 'config/chorus.defaults.yml'))

    @config = defaults.deep_merge(app_config)

    secret_key_file = File.join(@root_dir, 'config/secret.key')
    abort "No config/secret.key file found.  Run rake development:init or rake development:generate_secret_key" unless File.exists?(secret_key_file)
    @config['secret_key'] = File.read(secret_key_file).strip
  end

  def [](key_string)
    keys = key_string.split('.')
    keys.inject(@config) do |hash, key|
      hash.fetch(key)
    end
  rescue IndexError
    nil
  end

  def gpfdist_configured?
    (self['gpfdist.url'] && self['gpfdist.write_port'] && self['gpfdist.read_port'] &&
        self['gpfdist.data_dir'] && self['gpfdist.ssl'] != nil && true)
  end

  def tableau_configured?
    (self['tableau.url'] && self['tableau.port'] && self['tableau.username'] &&
     self['tableau.password'] && true)
  end

  def gnip_configured?
    (self['gnip_enabled']  && true)
  end

  def kaggle_configured?
    (self['kaggle.api_key'] && true)
  end

  def self.config_file_path(root_dir=nil)
    root_dir = Rails.root unless root_dir
    File.join root_dir, 'config/chorus.yml'
  end

  def config_file_path
    self.class.config_file_path(@root_dir)
  end

  private

  def set_root_dir(root_dir)
    @root_dir = root_dir || Rails.root
  end
end