require 'clockwork'
require 'queue_classic'

class JobScheduler
  include Clockwork

  def initialize
    every(Chorus::Application.config.chorus['instance_poll_interval_minutes'].minutes, 'InstanceStatusChecker.check') do
      QC.enqueue("InstanceStatusChecker.check")
    end

    every(Chorus::Application.config.chorus['delete_unimported_csv_files_interval_hours'].hours, 'CsvFile.delete_old_files!') do
      QC.enqueue("CsvFile.delete_old_files!")
    end

    every(Chorus::Application.config.chorus['reindex_search_data_interval_hours'].hours, 'SolrIndexer.refresh_external_data') do
      QC.enqueue("SolrIndexer.refresh_external_data")
    end

    every(1.minute, 'ImportScheduler.run') do
      # At present, we choose to enqueue the pending imports in this thread. If this becomes a bottleneck,
      # we may choose to run this in a separate queued job.
      ImportScheduler.run
    end

  end

  def job_named(job)
    @@events.find { |event|
      event.job == job
    }
  end

  def self.run
    JobScheduler.new.run
  end
end