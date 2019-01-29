class HashIterator(K,V)
  include iterable({K,V})
  @hash : Hash(K,V)
  def initialize(@hash);end
  def each

  end
  def to_yaml(yaml : YAML::Nodes::Builder)
    yaml.mapping(reference: self) do
      each do |k, v|
        k.to_yaml yaml
        v.to_yaml yaml
      end
    end
  end
end
