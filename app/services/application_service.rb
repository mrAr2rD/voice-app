class ApplicationService
  def self.call(...)
    new(...).call
  end

  private

  def success(data = nil)
    Result.new(success: true, data: data)
  end

  def failure(error, data: nil)
    Result.new(success: false, error: error, data: data)
  end
end
