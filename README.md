FIFO Cache
==========

**FIFO Cache** is fast hash-like fixed size cache class with FIFO 
functionality which removes oldest or less accessed records based on 
[implicit heap][1].

Usage is simple:
    
    require "fifocache"
    
    cache = Fifocache::new(3)   # or 300000, od sure :-)
    cache[:alfa] = 'alfa'
    cache[:beta] = 'beta'
    cache[:gama] = 'gama'
    cache[:delta] = 'delta'     # in this moment, :alfa is removed
    
But multiple addings are tracked, so subsequent call:

    cache[:beta] = 'beta'      # :beta, :gama, :delta in cache
    cache[:alfa] = 'alfa'      # :beta, :delta, :alfa in cache
    
…will cause `:gama` will be removed, not `:beta` because `:beta` is 
fresher now. And if you tune on *:dynamic mode*, also cache hits will 
be tracked, so:

    cache.mode = :dynamic       # you can do it in costructor too
    
    puts cache[:delta]          # cache hit
    cache[:gama] = 'gama'       # :beta, :delta, :gama in cache
    
…because `:beta` has been put-in two times, `:delta` has been hit 
recently, so `:alfa` is less accessed row and has been removed. In case 
of *:pure mode*, `:delta` would be removed of sure and `:alfa` kept.
    
Changing size of existing cache is possible although reducing the size
is generally rather slow because of necessity to remove all redundant 
"oldest" rows.
    

Contributing
------------

1. Fork it.
2. Create a branch (`git checkout -b 20101220-my-change`).
3. Commit your changes (`git commit -am "Added something"`).
4. Push to the branch (`git push origin 20101220-my-change`).
5. Create an [Issue][2] with a link to your branch.
6. Enjoy a refreshing Diet Coke and wait.


Copyright
---------

Copyright &copy; 2011 [Martin Kozák][3]. See `LICENSE.txt` for
further details.

[1]: http://www.cs.princeton.edu/courses/archive/spr09/cos423/Lectures/i-heaps.pdf
[2]: http://github.com/martinkozak/qrpc/issues
[3]: http://www.martinkozak.net/
