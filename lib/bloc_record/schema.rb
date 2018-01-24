require 'sqlite3'
 require 'bloc_record/utility'

 module Schema
   # table method allows us to call table on an object
   # to retrieve its SQL table name. BookAuthor class,
   # BookAuthor.table would return book_author
   def table
     BlocRecord::Utility.underscore(name)
   end

   # this method iterates thru the columns in a db table.
   # adds the name and type of each column as a key-value pair
   # to a hash called schema, then returns the hash.
   # An example of result: {"id"=>"integer", "name"=>"text", "age"=>"integer"}
   #
   # This is a LAZY LOADING design pattern,
   # i.e. @schema isn't calc until the first time it is needed,
   # instead of eager loading - calc when model is initialized
   def schema
     unless @schema
       @schema = {}
       connection.table_info(table) do |col|
         @schema[col["name"]] = col["type"]
       end
     end
     @schema
   end

   # this method returns the column names of the table
   def columns
     schema.keys
   end

   # this method returns the column names except the id number
   def attributes
     columns - ["id"]
   end

   # this method returns a count of record in the table
   # it starts building the connection between Ruby & SQL
   # the <<- is the heredoc operator- defines SQL as a terminator
   # the terminator is stored in a string and used for <<-,
   # in this case, it is passed to the execute method.
   def count
     connection.execute(<<-SQL)[0][0]
       SELECT COUNT(*) FROM #{table}
       SQL
   end
 end
