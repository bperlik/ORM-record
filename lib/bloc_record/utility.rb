# This utility file contains some general, reusable utility functions`
# for transforming the data.

module BlocRecord
  module Utility
    # Extend self to refer to Utility class, underscore will be a class
    # method instead of an instance method. Helpful to run code like
    # BlocRecord::Utility.underscore('TextLikeThis')
    extend self

    def underscore(camel_cased_word)
      # replaces any double colons with a slash using gsub
        string = camel_cased_word.gsub(/::/, '/')
      # insert an underscore between any all-caps class prefixs
      # (like acronyms) and other words
        string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      # inserts an underscore between any camelcased words
        string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      # replaces any - (dash) with an underscore using tr
        string.tr!("-", "_")
      # makes the string lowercase, of course!
        string.downcase
    end

    # this method converts string or numeric input into an
    # appropriately formated SQL string. Anything else passed in
    # is considered an error and converted to null
    def sql_strings(value)
      case value
        when String
          "'#{value}'"
        when Numeric
          value.to_s
        else
          "null"
      end
    end

    # this method takes an options hash and
    # converts all the keys to string keys
    # this allows the use of string or symbols as hash keys
    def convert_keys(options)
      options.keys.each {|k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol)}
      options
    end

    # this method converts an object's instance vars to a hash
    # by iterating over the object's instance variables
    # building a hash representation of those variables
    # ruby automatically prepends any instance variable name strings with @,
    # by deleting the prepend, we get just the name
    def instance_variables_to_hash(obj)
       Hash[obj.instance_variables.map{ |var| ["#{var.to_s.delete('@')}", obj.instance_variable_get(var.to_s)]}]
    end

    # this method takes an object, finds its db recod using find (selection module)
    # then it overwrites the instance var value with the db value
    # this discards any unsaved changes to the object
    def reload_obj(dirty_obj)
      persisted_obj = dirty_obj.class.find_one(dirty_obj.id)
       dirty_obj.instance_variables.each do |instance_variable|
         dirty_obj.instance_variable_set(instance_variable, persisted_obj.instance_variable_get(instance_variable))
       end
     end
  end
end

# example
# string = "SomeModule::SomeClass".gsub(/::/, '/')
#=> "SomeModule/SomeClass"
# string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
#=> nil
# string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
#=> "Some_Module/Some_Class"
# string.tr!("-", "_")
#=> nil
# string.downcase
#=> "some_module/some_class"
