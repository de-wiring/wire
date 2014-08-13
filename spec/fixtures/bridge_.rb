
class OVSBridge_Stub < Wire::Resource::ResourceBase
  def initialize(b_exist)
    super('OVSBridge_Stub')
    @b_exist = b_exist
  end

  def exist?
    @b_exist
  end

  def up?
    exist?
  end

  def up
  end

  def down?
    !(up?)
  end

  def down
  end

  def to_s
  end
end
