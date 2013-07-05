require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    other_class_name.constantize
  end

  def other_table_name
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name = name.to_s
    @params = params
  end

  def primary_key
    @params[:primary_key] || "id"
  end

  def foreign_key
    @params[:foreign_key] || "#{@name}_id"
  end

  def other_class_name
    @params[:class_name] || @name.to_s.camelize
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params)
    @name = name.to_s
    @params = params
  end

  def primary_key
    @params[:primary_key] || "id"
  end

  def foreign_key
    @params[:foreign_key] || "#{other_table_name}_id"
  end

  def other_class_name
    @params[:class_name] || @name.singularize.camelize
  end

  def type
    :has_many
  end

end

module Associatable

  def assoc_params
    @assoc_params ? @assoc_params : @assoc_params = {}
  end

  def belongs_to(name, params = {})
    assoc_params[name] = BelongsToAssocParams.new(name, params)
    aps = assoc_params[name]

    define_method(name) do 

      command = <<-SQL
        SELECT DISTINCT #{aps.other_table_name}.*
        FROM #{self.class.table_name} 
        INNER JOIN #{aps.other_table_name}
        ON #{aps.other_table_name}.#{aps.primary_key} = 
        #{self.class.table_name}.#{aps.foreign_key}
        WHERE #{aps.other_table_name}.#{aps.primary_key} = ?
      SQL

      results = DBConnection.execute(command, self.send(aps.foreign_key))
      aps.other_class.parse_all(results)
    end

  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params)

    define_method(name) do

      command = <<-SQL
        SELECT *
        FROM #{aps.other_table_name}
        WHERE #{aps.other_table_name}.#{aps.foreign_key} = (?)
      SQL

      results = DBConnection.execute(command, self.send(aps.primary_key))
      aps.other_class.parse_all(results)

    end
  end

  def has_one_through(name, assoc1, assoc2)
    aps1 = @assoc_params[assoc1]

    define_method(name) do
      aps2 = aps1.other_class.assoc_params[assoc2]
      
      command = <<-SQL
        SELECT #{aps2.other_table_name}.*
        FROM #{self.class.table_name}
        INNER JOIN #{aps1.other_table_name}
        INNER JOIN #{aps2.other_table_name}
        ON #{self.class.table_name}.#{aps1.foreign_key} =
        #{aps1.other_table_name}.#{aps1.primary_key} 
        AND #{aps1.other_table_name}.#{aps2.foreign_key} =
        #{aps2.other_table_name}.#{aps2.primary_key}
        WHERE #{self.class.table_name}.#{aps1.primary_key} = ?
      SQL
      p self.send(aps1.primary_key)
      p DBConnection.execute(command, self.send(aps1.primary_key))
    end

  end
end
