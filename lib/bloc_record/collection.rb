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
   end
 end
