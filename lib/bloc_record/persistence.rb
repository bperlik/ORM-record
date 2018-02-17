# this file will work directly with the database, so SQLite library
require 'sqlite3'
require 'pg'

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

  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  def destroy
    self.class.destroy(self.id)
  end

  # use method_missing to add support for dynamic update_*
  # and update_attributes
  def method_missing(method_name, * arguments, &block)
    if method_name.to_s =~ /update_(.*)/
      update_attribute($1, *arguments[0])
    else
      super
    end
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

    # chkpoint 5 update Assignment
    # Add functionality to allow #update to update multiple records
    # people = { 1 => { "first_name" => "David" }, 2 => { "first_name" => "Jeremy" } }
    # Person.update(people.keys, people.values)
    def update(ids, updates)
      # 1 convert the non-id parameters to an array
      updates = BlocRecord::Utility.convert_keys(updates)
      updates.delete "id"
      # 2 convert updates to an array of strings
      #   each string is in the format KEY=VALUE
      #   this updates the specified columns in the db
      updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

      # 8 determine the class type of ids
      # the class type is used to determine the where clause
      if ids.class == Fixnum
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
      else
        where_clause = ";"
      end

      # 3 execute a full SQL statement, string will interpolate to
      # UPDATE table_name
      # SET column1=value1, column2=value2,...
      # WHERE id=id1;
      connection.execute <<-SQL
        UPDATE #{table}
        SET #{updates_array * ","} #{where_clause}
      SQL

      true
    end

    def update_all(updates)
      update(nil, updates)
    end

    # this method supports deleting more than one item
    # with the splat operator
    # and an where_clause determined by the length
    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end

    # this method destroys all records
    # but use an optional conditions_hash to
    # allow destroying records with specific attribute values
    def destroy_all(conditions_hash=nil)
      if conditions_hash && !conditions_hash.empty?
        conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
        conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

        connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL
      end

      true
    end
  end
end
