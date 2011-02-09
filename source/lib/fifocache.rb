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
# For touches tracking utilizes heap queue.
#
    
class FifoCache

    @data
    @queue
    @counts
    
    ##
    # Contains maximal size of the cache.
    # @return [Integer] maximal size of the cache
    #
    
    attr_accessor :size
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
                dkey = @queue.delete_min
                @data.delete(dkey)
                @counts.delete(dkey)
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
    
end
