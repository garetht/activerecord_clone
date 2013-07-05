require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name.underscore
  end

  def self.all
    command = <<-SQL
      SELECT *
      FROM #{table_name}
    SQL

    results = DBConnection.execute(command)
    parse_all(results)
  end

  def self.find(id)
    command = <<-SQL
      SELECT *
      FROM #{table_name}
      WHERE id = #{id}
    SQL

    results = DBConnection.execute(command)
    parse_all(results)
  end

  def save
    @id ? update : create
  end

  def attribute_values
    self.class.attributes.map do |attribute|
      send(attribute)
    end
  end

  private
  def create
    attr_vals = attribute_values
    command = <<-SQL
      INSERT INTO #{self.class.table_name} (#{self.class.attributes.join(", ")})
      VALUES (#{(["(?)"] * attr_vals.length).join(", ")})
    SQL
    DBConnection.execute(command, *attr_vals)
    @id = DBConnection.last_insert_row_id
  end

  def update
    set_command = self.class.attributes.map do |attribute|
      "#{attribute} = (?)"
    end.join(", ")
    command = <<-SQL
      UPDATE #{self.class.table_name}
      SET #{set_command}
      WHERE id = #{@id}
    SQL
    DBConnection.execute(command, attribute_values)
  end

end

if __FILE__ == $PROGRAM_NAME
  DBConnection.open('../../test/cats.db')

  class Cat < SQLObject
    set_attrs :id, :name, :owner_id
    set_table_name "cats"
    belongs_to :human, foreign_key: "owner_id"
    puts "self.classcat #{self.class}"
    has_one_through :house, :human, :house
  end

  mousecat = Cat.find(3).first
  #mousecat.save

  class Human < SQLObject
    set_attrs :id, :fname, :lname, :house_id
    set_table_name "humans"
    has_many :cats, foreign_key: "owner_id"
    belongs_to :house
  end

  cathuman = Human.find(3).first
  #cathuman.save

  mittens = Cat.find(4).first
  dittens = Cat.find(6).first


  harley = Human.find(4).first


  class House < SQLObject
    set_table_name "houses"
    set_attrs :id, :address, :house_id
  end

  puts "Cathuman's cats: #{cathuman.cats}"
  p dittens.id
  puts "Ditten's house: #{dittens.house}"

end