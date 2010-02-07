# You can now call foo from the main interp and have the coroutine
# named foo run in the slave; when the coroutine yields, you are back
# in the main interp. Is this somehow related to what you really
# wanted to do?

set int [interp create -safe]
$int eval coroutine accumulator {
    apply {
	{} {
	    set x 0
	    while 1 {
		incr x [yield $x]
	    }
	}
    }
}

interp alias {} accumulator $int accumulator

for {set i 0} {$i < 10} {incr i} {
    puts "$i -> [accumulator $i]"
}
