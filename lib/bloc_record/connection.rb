# This module is used to encapsulate the connection related code.
# It imports the SQLite library, defines the module, and passes the db filename
# A new db object will be initialized from the file
# the first time connection is called.

require 'sqlite3'
require 'pg'

module Connection
  def connection
    if BlocRecord.database_platform == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif BlocRecord.database.platform == :pg
      @connection ||= PG::Connection.open(:dbname => BlocRecord.database_filename)
    end
  end
end
