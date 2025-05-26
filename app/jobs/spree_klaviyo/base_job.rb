module SpreeKlaviyo
  class BaseJob < ApplicationJob
    queue_as SpreeKlaviyo.queue
  end
end
