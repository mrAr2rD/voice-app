class Result
  attr_reader :data, :error

  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def on_success
    yield(data) if success? && block_given?
    self
  end

  def on_failure
    yield(error, data) if failure? && block_given?
    self
  end
end
