class ApplicationService
  Result = Data.define(:success?, :value, :errors)

  private

  def success(value = nil)
    Result.new(true, value, [])
  end

  def failure(errors)
    Result.new(false, nil, Array(errors))
  end
end
