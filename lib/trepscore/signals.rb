module TrepScore
  # Raised when a service hook needs to be retried. Services that raise this
  # signal will be tried again in the near future. If a delay count is provided
  # the service won't be retried until after that number of seconds.
  class NotReadySignal < Exception
    attr_reader :delay
    def initialize(delay = nil)
      @delay = delay
    end
  end
end
