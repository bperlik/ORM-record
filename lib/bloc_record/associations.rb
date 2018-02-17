require 'sqlite3'
require 'pg'
require 'active_support/inflector'

module Associations
  def has_many(association)
    # this method is an example of metaprogramming - a program to create a program
    # this one adds an instance method, entries to AddressBook class
    # by calling define_method, adds a new method at runtime
    # useful if you don't know what those methods should be named while coding
    # example in https://stackoverflow.com/questions/302789/can-i-define-method-in-rails-models/303744#303744
    define_method(association) do
      # execute an SQL using where
      rows = self.class.connection.execute <<-SQL
         SELECT * FROM #{association.to_s.singularize}
         WHERE #{self.class.table}_id = #{self.id}
      SQL

      class_name = association.to_s.classify.constantize
      collection =BlocRecord::Collection.new

      # iterate thru each SQL record using rows,
      # serialize it into an Entry object,
      # and add to the collection
      rows.each do |row|
        collection << class_name.new(Hash[class_name.columns.zip(row)])
      end

      # return the entire collection
      collection
    end
  end

  # belongs_to method adds the ability to traverse up the graph
  # if class Collection_Member has belongs_to :collection_name
  # then collection_name is now a method to find parent of collection_member
  # in collection_member.collection_name
  # Notice differences in has_many and  belongs_to
  # 1) has_many uses singularize bec items are many/ belongs_to uses one association
  # 2) belongs_to uses get_first_row instead of execute bec only one record is returned
  def belongs_to(association)
    define_method(association) do
      association_name = association.to_s
      row = self.class.connection.get_first_row <<-SQL
        SELECT * FROM #{association_name}
        WHERE id = #{self.send(association_name + "_id")}
      SQL

      class_name = association_name.classify.constantize

      if row
        data = Hash[class_name.columns.zip(row)]
         class_name.new(data)
      end
    end
  end

  # 7 DB Association Assignment 1
  # Add support for only one association
  def has_one(association)
    define_method(association) do
      row = self.class.connection.get_first_row <<-SQL
        SELECT * FROM #{association.to_s.singularize}
        WHERE #{self.class.table}_id = #{self.id}
      SQL

      class_name = association_name.to_s.classify.constantize

      if row
        class_name.new(Hash[class_name.columns.zip(row)])
      end
    end
  end
end
