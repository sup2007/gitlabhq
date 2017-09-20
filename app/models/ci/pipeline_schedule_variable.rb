module Ci
  class PipelineScheduleVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    include HasVariable

    belongs_to :pipeline_schedule

    validates :key, uniqueness: { scope: :pipeline_schedule_id }
  end
end
