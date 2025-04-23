class Return < StandardError
  attr_reader :value

  def initialize(value)
    @value = value
    super(nil)
  end
end
