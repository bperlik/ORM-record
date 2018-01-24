# This module is used to encapsulate the connection related code.
# It imports the SQLite library, defines the module, and passes the db filename
# A new db object will be initialized from the file
# the first time connection is called.

require 'sqlite3'

module Connection
  def connection
    @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
  end
end
