 require 'bloc_record/utility'
 require 'bloc_record/schema'
 require 'bloc_record/persistence'
 require 'bloc_record/selection'
 require 'bloc_record/connection'
 require 'bloc_record/collection'
 require 'bloc_record/associations'

 # this module has most of its functionality from other modules
 # in order to bre more readable and easy to understand
 module BlocRecord
   class Base
     include Persistence
     extend Selection
     extend Schema
     extend Connection
     extend Associations

     # this initializer filters the options hash
     # using convert_keys method, iterating over each column
     # Using self.class to get the class's dynamic runtime type
     # and calls columns on that type
     def initialize(options={})
       options = BlocRecord::Utility.convert_keys(options)

       # this each block does two things
       # 1) Object::send... sends the column name to attr_acessor
       #    and creates an instance variable getter and setter for each column
       # 2) Object::instance_variable_set...sets the instance variable
       #    to the value corresponding to that key in the options hash
       self.class.columns.each do |col|
         self.class.send(:attr_accessor, col)
         self.instance_variable_set("@#{col}", options[col])
       end
     end
   end
 end
