module BlocRecord
   class Collection < Array
     # 5 take an array updates
     # then set ids using self.map
     # if there are items in Collection, call class method
     # self.first.class.udpate(ids, updates) with the array of ids
     # and hash of updates as parameters
     def update_all(updates)
       ids = self.map(&:id)
       # 6 if there are any items in array, use update method
       # otherwise return false to indicate nothing was updated
       self.any? ? self.first.class.update(ids, updates) : false
     end

    # Chkpoint 5 Update Assignment 3
    # Add instance method take to handle
    # Person.where(first_name: 'John').take
    def take(num=1)
      ids = self.map(&:id)
      take_collection = Collection.new

      (0...num).each do |i|
        take_collection << self[i]
      end
      take_collection
    end

    # Chkpoint 5 Update Assignment 3
    # Add instance method where to handle
    # Person.where(first_name: 'John').where(last_name: 'Smith')
    def where(*args)
      ids = self.map(&:id)

      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ")
        end
      end
      if expression.nil?
        expression = "1 = 1"
      end
      # where("email = ? AND phone = ?", useremail, phone)
      string = "id IN (#{ids.join ","}) AND #{expression}"
      # WHERE id IN (1, 3, 5, ...)
      self.any? ? self.first.class.where(string) : false
    end

    # Assignment 5 Update - add input validation and error handling
    # add instance method to BlocRecord::Collection
    # to handle not :'Person.where.not(first_name:'John')
    def not(*args)
      ids = self.map(&:id)

      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "NOT #{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ")
        end
      end
      string = "id IN (#{ids.join ","}) AND #{expression}"
      self.any? ? self.first.class.where(string) : false
    end

    # Assignment 6 Destroy - add support for strings and array conditions in the destroy_all method
    # to handle Entry.destroy_all("phone_number = '999-999-9999'")
    # and Entry.destroy_all("phone_number = ?", '999-999-9999')
    def destroy_all(*args)
       ids = self.map(&:id)
       if args.count > 1
         expression = args.shift
         params = args
       else
         case args.first
         when String
           expression = args.first
         when Hash
           expression_hash = BlocRecord::Utility.convert_keys(args.first)
           expression = expression_hash.map { |key, value| "NOT #{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ")
         end
         params = []
       end
       group = "id IN (#{ids.join ","}) AND #{expression}"
       params.unshift group
       self.any? ? self.first.class.destroy_all(*params) : false
     end

    def method_missing(method_name, *arguments, &block)
      if method_name.to_s =~ /update_(.*)/
        updates = {}
        updates[$1] = arguments[0]
        update_all(updates)
      else
        super
      end
     end
   end
 end
