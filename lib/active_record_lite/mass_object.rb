class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes.map(&:to_sym)
    attributes.each { |attribute| attr_accessor attribute.to_sym }
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    set_attrs(*results.first.keys)
    returned_results = []
    results.each {|row| returned_results << new(row)}
    returned_results
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        send("#{attr_name}=".to_sym, value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end

class MyClass < MassObject
  set_attrs :x, :y
end

if __FILE__ == $PROGRAM_NAME
  MyClass.new(:x => :x_val, :y => :y_val)
end
