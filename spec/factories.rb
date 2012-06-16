FactoryGirl.define do
  factory :user, :aliases => [:owner, :modifier, :actor] do
    sequence(:username) { |n| "user#{n}" }
    password "secret"
    first_name "John"
    last_name "Doe"
    title "Grand Poo Bah"
    dept "Corporation Corp., Inc."
    notes "One of our top performers"
    sequence(:email) { |n| "person#{n}@example.com" }
  end

  factory :admin, :parent => :user do
    first_name "Admin"
    last_name "User"
    admin true
  end

  factory :instance, :aliases => [:greenplum_instance] do
    sequence(:name) { |n| "instance#{n}" }
    sequence(:host) { |n| "host#{n}.emc.com" }
    sequence(:port) { |n| 5000+n }
    maintenance_db "postgres"
    owner
    version "9.1.2 - FactoryVersion"
  end

  factory :hadoop_instance do
    sequence(:name) { |n| "instance#{n}" }
    sequence(:host) { |n| "host#{n}.emc.com" }
    sequence(:port) { |n| 5000+n }
    owner
  end

  factory :instance_account do
    sequence(:db_username) { |n| "username#{n}" }
    db_password "secret"
    owner
    instance
  end

  factory :gpdb_database do
    sequence(:name) { |n| "database#{n}" }
    instance
  end

  factory :gpdb_schema do
    sequence(:name) { |n| "schema#{n}" }
    association :database, :factory => :gpdb_database
  end

  factory :gpdb_table do
    sequence(:name) { |n| "table#{n}" }
    association :schema, :factory => :gpdb_schema
  end

  factory :gpdb_view do
    sequence(:name) { |n| "view#{n}" }
    association :schema, :factory => :gpdb_schema
  end

  factory :dataset_statistics do
    initialize_with do
      new({
        'table_type' => 'BASE_TABLE',
        'row_count' => '1000',
        'column_count' => '5',
        'description' => 'This is a nice table.',
        'last_analyzed' => '2012-06-06 23:02:42.40264+00',
        'disk_size' => '2048 kB',
        'partition_count' =>  '0',
        'definition' => "SELECT * FROM foo"
      })
    end
  end

  factory :workspace do
    sequence(:name) { |n| "workspace#{n}" }
    owner
    after(:create) do |workspace|
      FactoryGirl.create(:membership, :workspace => workspace, :user => workspace.owner)
    end
  end

  factory :membership do
    user
    workspace
  end

  factory :workfile do
    owner
    workspace
    description "A nice description"
    file_name "workfile.doc"
  end

  factory :workfile_version do
    workfile
    version_num "1"
    owner
    commit_message "Factory commit message"
    modifier
  end
  
  factory :workfile_draft do
    owner
    workfile
    content "A nice content"
  end

  factory :associated_dataset do
    association :dataset, :factory => :gpdb_table
    workspace
  end

  factory :event, :class => Events::Base do
    actor

    factory :greenplum_instance_created_event, :class => Events::GREENPLUM_INSTANCE_CREATED do
      greenplum_instance
    end

    factory :hadoop_instance_created_event, :class => Events::HADOOP_INSTANCE_CREATED do
      hadoop_instance
    end

    factory :greenplum_instance_changed_owner_event, :class => Events::GREENPLUM_INSTANCE_CHANGED_OWNER do
      greenplum_instance
      new_owner :factory => :user
    end

    factory :greenplum_instance_changed_name_event, :class => Events::GREENPLUM_INSTANCE_CHANGED_NAME do
      greenplum_instance
      new_name "new_instance_name"
      old_name "old_instance_name"
    end

    factory :hadoop_instance_changed_name_event, :class => Events::HADOOP_INSTANCE_CHANGED_NAME do
      hadoop_instance
      new_name "new_instance_name"
      old_name "old_instance_name"
    end
  end
end

