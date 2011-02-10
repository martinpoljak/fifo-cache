# encoding: utf-8
# (c) 2010-2011 Martin Kozák (martinkozak@martinkozak.net)

require "depq"

##
# Represents cache object accessible by similar way as hash,
# but with fixed capacity with FIFO funcionality.
#
# It's useful for limited size caches. Oldest cache records are removed.
# Also can be used in dynamic mode, so the less acessed cache records 
# are removed instead of the oldest records in that case.
#
# For touches tracking utilizes implicit heap queue.
#
    
class Fifocache

    @data
    @queue
    @counts
    
    ##
    # Contains maximal size of the cache.
    # @return [Integer] maximal size of the cache
    #
    
    attr_reader :size
    @size
    
    ##
    # Indicates mode of the cache.
    # @return [:pure, :dynamic] mode of the cache
    #
    
    attr_accessor :mode
    @mode

    ##
    # Constructor. Initializes cache to appropriate size.
    #
    # @param [Integer] site size of the cache
    # @param [:pure, :dynamic] mode mode of the caching (see class description)
    #
    
    def initialize(size, mode = :pure)
        @data = { }
        @queue = Depq::new
        @counts = { }

        @size = size
        @mode = mode
    end

    ##
    # Puts item with key to cache.
    #
    # One item can be putted more times to cache. In this case is 
    # relevant the latest put.
    #
    # @param [Object] key item key
    # @param [Object] item item value
    #
    
    def []=(key, item)

        # Adds to cache
        
        if not self.has_key? key
        
            # Inserts to tracking structures
            @data[key] = item
            locator = @queue.insert(key, 1)
            @counts[key] = locator
                
            # Eventually removes first (last)
            if self.length > @size
                self.clean!
            end
            
        else
            self.touch(key)
        end

    end

    ##
    # Returns item from cache.
    #
    # @param [Object] key item key
    # @return [Object] item value
    #
    
    def [](key)
        if mode == :dynamic
            self.touch(key)
        end
        
        @data[key]
    end
    
    ##
    # Indicates key is in cache.
    #
    # @param [Object] key item key
    # @return [Boolean] +true+ it it is, +false+ otherwise
    #
    
    def has_key?(key)
        @data.has_key? key
    end
    
    alias :"include?" :"has_key?"
    
    ##
    # Touches key in cache.
    # @param [Object] key item key
    #
    
    def touch(key)
        locator = @counts[key]
        locator.update(key, locator.priority + 1)
    end
    
    ##
    # Indicates current size of the cache.
    # @return [Integer] current size of the cache
    #
    
    def length
        @data.length
    end
    
    ##
    # Sets new size.
    # @param [Integer] size new size
    #
    
    def size=(size)
        if size < self.length
            self.clean(self.length - size)
        end
    end
    
    ##
    # Removes key.
    #
    # @param [Object] key item key
    # @return [Object] removed item value
    #
    
    def remove(key)
        if self.has_key? key
            # Heap queue
            locator = @counts[key]
            @queue.delete_element(locator)
            
            # Data holders
            result = @data[key]
            @data.delete(key)
            @counts.delete(key)
        else
            result = nil
        end
            
        return result
    end
    
    ##
    # Cleans specified number of slots.
    # @return [Hash] removed pairs
    #
    
    def clean!(count = 1)
        result = { }
        count.times do
            dkey = @queue.find_min
            result[dkey] = self.remove(dkey)  
            
            if data.empty?
                break
            end
        end
        
        return result
    end
    
    alias :clean :"clean!"
    
    ##
    # Clear whole cache.
    #
    
    def clear!
        @data.replace({ })
        @counts.replace({ })
        @queue = Depq::new
    end
    
    alias :clear :"clear!"
    
end
    
