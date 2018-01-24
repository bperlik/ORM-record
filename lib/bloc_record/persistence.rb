# this file will work directly with the database, so SQLite library
require 'sqlite3'
# this file needs the awareness of the schema
require 'bloc_record/schema'

module Persistence

  # this method:
  # 1) takes a hash called attrs, converts to array of strings in an array
  # 2) writes the changes to the database
  # 3) creates and returns a ruby character object
  # Note attributes is an array of the column names
  # and attrs is the hash passed in to the create method.

  def self.included(base)
    base.extend(ClassMethods)
  end

  # this method saves the values to the database
  # the first one without the exclamation point rescue the failed attempts
  # by calling save!
  def save
    self.save! rescue false
  end

  def save!
    # delegate to create method if there this is new item with no id yet
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    # fields are comma-delimited string of column names and values
    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    # pass the values, table name and id to an SQL update statement
    self.class.connection.execute <<-SQL
       UPDATE #{self.class.table}
       SET #{fields}
       WHERE id = #{self.id};
    SQL

    # return true to indicate success
    true
  end

  # to make create be a class method
  # we define a nested module called ClassMethods
  # self.included is called whenever this module is included.
  # extend automatically adds the ClassMethods methods to Persistence
  module ClassMethods
    def create(attrs)
      # 1) the values are converted to SQL strings
      # and mapped to an array(vals)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

      # 2) The values are then used to form the INSERT INTO SQL statement
      # This writes the changes to the database
      connection.execute <<-SQL
       INSERT INTO #{table} (#{attributes.join ","})
       VALUES (#{vals.join ","});
      SQL

      # 3) now we will create and return a ruby character object
      # creates data (a hash of attributes and values),
      # then retrieves the id and adds it to the data hash,
      # then pass the hash to new which creates the new object
      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end
  end
end
