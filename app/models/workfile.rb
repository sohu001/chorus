class Workfile < ActiveRecord::Base
  include SoftDelete

  attr_accessible :description, :file_name, :versions_attributes

  belongs_to :workspace
  belongs_to :execution_schema, :class_name => 'GpdbSchema'
  belongs_to :owner, :class_name => 'User'

  has_many :versions, :class_name => 'WorkfileVersion', :order => 'version_num DESC'
  has_many :drafts, :class_name => 'WorkfileDraft'
  has_many :activities, :as => :entity
  has_many :events, :through => :activities
  has_and_belongs_to_many :events_notes, :class_name => 'Events::Note'

  belongs_to :latest_workfile_version, :class_name => 'WorkfileVersion'

  validates_format_of :file_name, :with => /^[a-zA-Z0-9_ \.\(\)\-]+$/

  before_validation :init_file_name, :on => :create

  accepts_nested_attributes_for :versions

  attr_accessor :highlighted_attributes, :search_result_notes
  searchable do
    text :file_name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    integer :workspace_id, :multiple => true
    integer :member_ids, :multiple => true
    boolean :public
    string :grouping_id
    string :type_name
    string :security_type_name
  end

  def self.add_search_permissions(current_user, search)
    unless current_user.admin?
      search.build do
        any_of do
          without :security_type_name, Workfile.security_type_name
          with :member_ids, current_user.id
          with :public, true
        end
      end
    end
  end

  def self.create_from_svg(attributes, workspace, owner)
    transcoder = SvgToPng.new(attributes[:svg_data])
    workfile = new(:versions_attributes => [{:contents => transcoder.fake_uploaded_file(attributes[:file_name]), :owner => owner, :modifier => owner}])
    workfile.owner = owner
    workfile.workspace = workspace
    workfile.save!
    workfile.reload
  end

  def self.create_from_file_upload(attributes, workspace, owner)
    workfile = new(attributes)
    workfile.owner = owner
    workfile.workspace = workspace

    version = nil

    if(workfile.versions.first)
      version = workfile.versions.first
    else
      version = workfile.versions.build
      filename = workfile.file_name
      version.contents = File.new(File.join('/tmp/',filename), 'w')
    end

    version.owner = owner
    version.modifier = owner

    workfile.save!

    workfile.reload
  end

  def build_new_version(user, source_file, message)
    versions.build(
      :owner => user,
      :modifier => user,
      :contents => source_file,
      :version_num => last_version_number + 1,
      :commit_message => message,
    )
  end

  def has_draft(current_user)
    !!WorkfileDraft.find_by_owner_id_and_workfile_id(current_user.id, id)
  end

  def copy(user, workspace)
    workfile = Workfile.new
    workfile.file_name = file_name
    workfile.description = description
    workfile.workspace = workspace
    workfile.owner = user

    workfile
  end

  def member_ids
    workspace.member_ids
  end

  def public
    workspace.public
  end

  def validate_name_uniqueness
    exists = Workfile.exists?(:file_name => file_name, :workspace_id => workspace.id)
    if exists
      errors.add(:file_name, "is not unique.")
      false
    else
      true
    end
  end

  private
  def last_version_number
    latest_workfile_version.try(:version_num) || 0
  end

  def init_file_name
    self.file_name ||= versions.first.file_name
    WorkfileName.resolve_name_for!(self)
  end
end
