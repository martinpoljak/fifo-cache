# encoding: utf-8
# (c) 2010-2011 Martin Kozák (martinkozak@martinkozak.net)

require "hash-utils/object"
require "depq"

##
# Represents cache object accessible by similar way as hash,
# but with fixed capacity with FIFO funcionality.
#
# It's useful for limited size caches. Oldest cache records are removed.
# Also can be used by dynamic mode, so the less putted or less accessed 
# (or both) cache records are removed instead of the oldest records in 
# that cases.
#
# For touches tracking utilizes implicit heap queue.
#
    
class Fifocache

    @data
    @queue
    @counts
    
    ##
    # Integer overflow protection.
    #
    
    INFINITY = 1.0/0
    
    ##
    # Contains maximal size of the cache.
    # @return [Integer] maximal size of the cache
    #
    
    attr_reader :size
    @size
    
    ##
    # Indicates puts should be tracked.
    # @return [Boolean]
    #
    
    attr_accessor :puts
    @puts
    
    ##
    # Indicates hits should be tracked.
    # @return [Boolean]
    #
    
    attr_accessor :hits
    @hits
    
    ##
    # Indicates new items handicap factor.
    #
    # Handicap factor is multiplier of the min hits count of all items in 
    # the cache. It's important set it in some cases. See {#[]=}.
    #
    # @return [Float]
    # @see #[]=
    #
    
    attr_accessor :factor
    @factor

    ##
    # Constructor. Initializes cache to appropriate size.
    #
    # @param [Integer] site size of the cache
    # @param [Hash] opts tracking options
    # @option opts [Boolean] :puts indicates, puts should be tracked
    # @option opts [Boolean] :hits indicates, hits should be tracked
    # @option opts [Float, Integer] :factor indicates new items priority correction factor
    #
    
    def initialize(size, opts = {  })
        @data = { }
        @queue = Depq::new
        @counts = { }

        @size = size
        @puts = opts[:puts].to_b
        @hits = opts[:hits].to_b
        @factor = opts[:factor].to_f
    end

    ##
    # Puts item with key to cache.
    #
    # If tracking is turned on and no {#factor} explicitly set, handicap
    # 1 is assigned to new items. It's safe, but not very acceptable 
    # because cache will become static after filling. So it's necessary 
    # (or at least higly reasonable) to set priority weighting factor to 
    # number higher than 1 according dynamics of your application.
    #
    # @param [Object] key item key
    # @param [Object] item item value
    # @see #factor
    #
    
    def []=(key, item)

        # Adds to cache
        
        if not self.has_key? key
        
            # Inserts to tracking structures
            @data[key] = item
            locator = @queue.insert(key, __new_priority)
            @counts[key] = locator
                
            # Eventually removes first (last)
            if self.length > @size
                self.clean!
            end
            
        elsif @puts
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
        if @hits
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
        priority = locator.priority + 1
        
        if priority != self.class::INFINITY
            locator.update(key, locator.priority + 1)
        end
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
    
    alias :resize :"size="
    
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
            @queue.delete_locator(locator)
            
            # Data holders
            result = __purge(key)
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
            dkey = @queue.delete_min
            result[dkey] = __purge(dkey)  
            
            if @data.empty?
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
        @queue.clear
    end
    
    alias :clear :"clear!"
    
    ##
    # Converts to hash.
    # @return [Hash] cache data
    #
    
    def to_h
        @data.dup
    end
    
    
    private
    
    ##
    # Purges item from data holders.
    #
    
    def __purge(key)
        result = @data[key]
        @data.delete(key)
        @counts.delete(key)

        return result
    end
    
    ##
    # Returns new priority.
    #
    
    def __new_priority
        if (@puts or @hits) and (@factor != 0)
            min = @queue.find_min_locator
            priority = min.nil? ? 1 : (min.priority * @factor)
        else
            priority = 1
        end
        
        return priority
    end
    
end
    
