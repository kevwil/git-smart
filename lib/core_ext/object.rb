class Object
  def tapp(prefix = nil, &block)
    block ||= ->(x) { x }
    str = block[self].is_a? String ? block[self] : block[self].inspect
    puts [prefix, str].compact.join(': ')
    self
  end
end
