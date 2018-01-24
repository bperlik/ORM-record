require 'sqlite3'

 # this module adds the ability to find and return a record by ID
 # 1) write an SQL query
 # 2) return the a model object with the result of the query
 module Selection
   def find(id)
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE id = #{id};
     SQL

     data = Hash[columns.zip(row)]
     new(data)
   end
 end
