class DummyParser
 include Hpricot
  def self.parse(response)
    Hpricot.parse(response)
  end
end

