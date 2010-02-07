namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::*

set ::tick 0

###############################################################################
#
# rand routine, scarffed from a comp.lang.tcl posting
#    From: eichin@cygnus.com (Mark Eichin)
#

set ::lastvalue [expr ([pid]*[file atime /dev/tty])%65536]

proc rawrand {} {
    # per Knuth 3.6:
    # 65277 mod 8 = 5 (since 65536 is a power of 2)
    # c/m = .5-(1/6)\sqrt{3}
    # c = 0.21132*m = 13849, and should be odd.
    set ::lastvalue [expr (65277*$::lastvalue+13849)%65536]
    set ::lastvalue [expr ($::lastvalue+65536)%65536]
    return $::lastvalue
}
proc rand {base} {
    set rr [rawrand]
    return [expr abs(($rr*$base)/65536)]
}


proc syscall {args} {
    set robot [lindex $args 0]
    set syscall [lrange $args 1 end]
    set result 0

    if {[lindex $syscall 0] eq "rand"} {
	set result [rand [lindex $syscall 1]]
    } else {
	set ::data($robot,syscall,$::tick) $syscall
    }
    puts -nonewline "syscall: "
    foreach arg $args {
	puts -nonewline "$arg "
    }
    puts ""

    return $result
}

proc init {} {
    set ::robots {r1}
    #set f [open robot1.tr]
    #set ::robotData(r1,code) [read $f]


    foreach robot $::robots {
	set ::data($robot,interp) [interp create -safe]

	#set name [file tail $fn]
	set name $robot
	set x [rand 999]
	set y [rand 999]

	# generate a new signature
	set newsig [rand 65535]

	#########
	# set robot parms
	#########
	# window name = source.file_randnumber
	set ::data($robot,name) ${name}_$newsig
	# the rand number as digital signature
	set ::data($robot,num) $newsig
	# robot status: 0=not used or dead, 1=running 
	set ::data($robot,status)	1
	# robot current x
	set ::data($robot,x) $x
	# robot current y
	set ::data($robot,y) $y
	# robot origin  x since last heading
	set ::data($robot,orgx) $x
	# robot origin  y   "    "     "
	set ::data($robot,orgy) $y
	# robot current range on this heading
	set ::data($robot,range) 0
	# robot current damage
	set ::data($robot,damage) 0
	# robot current speed
	set ::data($robot,speed) 0
	# robot desired   "
	set ::data($robot,dspeed)	0
	# robot current heading
	set ::data($robot,hdg) [rand 360]
	# robot desired   "
	set ::data($robot,dhdg) $::data($robot,hdg)
	# robot direction of turn (+/-)
	set ::data($robot,dir) +
	# robot last scan dsp signature
	set ::data($robot,sig) "0 0"
	# missile state: 0=avail, 1=flying
	set ::data($robot,mstate) 0
	# missile reload time: 0=ok, >0 = reloading
	set ::data($robot,reload) 0
	# number of missiles used per clip
	set ::data($robot,mused) 0
	# missile current x
	set ::data($robot,mx) 0
	# missile current y
	set ::data($robot,my) 0
	# missile origin  x
	set ::data($robot,morgx) 0		
	# missile origin  y
	set ::data($robot,morgy) 0
	# missile heading
	set ::data($robot,mhdg) 0
	# missile current range
	set ::data($robot,mrange)	0
	# missile target distance
	set ::data($robot,mdist) 0
	# motor heat index
	set ::data($robot,heat) 0
	# overheated flag
	set ::data($robot,hflag) 0
	# signature of last robot to scan us
	set ::data($robot,ping) 0
	# declared team
	set ::data($robot,team) ""
	# last team message sent
	set ::data($robot,data) ""
	# barrel temp, affected by cannon fire
	set ::data($robot,btemp) 0
	# request from robot slave interp to master
	set ::data($robot,syscall,0) {}
	# return value from master to slave interp
	set ::data($robot,sysreturn,0) {}

	interp alias $::data($robot,interp) syscall {} syscall $robot

	$::data($robot,interp) invokehidden source syscalls.tcl

	#    $data($robot,interp) invokehidden source robot1.tr

	if {$robot eq "r1"} {
	    $::data($robot,interp) eval coroutine ${robot}Run {
		apply {
		    {} {
			set dir [rand 360]
			set nothing 0
			set closest 0
			while {1} {
			    set rng [scanner $dir 10]
			    dputs "rng: $rng"
			    if {$rng > 0 && $rng < 700} {
				set start [expr ($dir+20)%360]
				for {set limit 1} {$limit <= 40} {incr limit} {
				    set dir [expr ($start-($limit)+360)%360]
				    set rng [scanner $dir 1]
				    dputs "rng: $rng"
				    if {$rng > 0 && $rng < 700} {
					set nothing 0
					cannon $dir $rng
					drive $dir 70
					incr limit -4}}} else {
					    incr nothing
					    if {$rng > 700} {set closest $dir}}
			    drive 0 0
			    if {$nothing >= 30} {
				set nothing 0
				drive $closest 100
				after 10000 drive 0 0}
			    set dir [expr ($dir-20+360)%360]}
		    }
		}
	    }
	} elseif {$robot eq "r2"} {
	    $::data($robot,interp) eval coroutine ${robot}Run {
		apply {
		    {} {
			set corners {{10 10} {990 10} {10 990} {990 990}  }
			set cor_dir   {0       90       270      180}
			set dam [damage]
			proc I_was_scanned {who} {
			    dputs $who scanned me
			}
			alert I_was_scanned
			proc goto {x y} {
			    set rad2deg 57.2958
			    set hdg [expr int( $rad2deg * atan2(($y-[loc_y]),($x-[loc_x])) )]
			    if {$hdg < 0} {incr hdg 360}
			    drive $hdg 100
			    while { abs($x-[loc_x]) > 40 || abs($y-[loc_y]) > 40} {
				set hdg [expr int($rad2deg * atan2(($y-[loc_y]),($x-[loc_x])))]
				if {$hdg < 0} {incr hdg 360}
				if {[speed] <= 35} {
				    drive $hdg 100
				    global _debug
				    if {$_debug} {dputs hdg: $hdg to $x $y}
				}
			    }
			    drive $hdg 0
			}
			set x [loc_x]
			set y [loc_y]
			if {$x < 500} { set x 10; set s1 0 } else { set x 990; set s1 1 }
			if {$y < 500} { set y 10; set s2 0 } else { set y 990; set s2 1 }
			if { $s1 &&  $s2} { set start 180; set new_corner 3 }
			if { $s1 && !$s2} { set start  90; set new_corner 1 }
			if {!$s1 &&  $s2} { set start 270; set new_corner 2 }
			if {!$s1 && !$s2} { set start   0; set new_corner 0 }
			set resincr 5
			goto $x $y
			while {1} {
			    set num_scans 5
			    set dir $start
			    while { $num_scans > 0 && $dam+10 > [damage] } {
				set rng [scanner $dir $resincr]
				if {$rng >0 && $rng <= 700} {
				    set resincr 1
				    cannon $dir $rng
				    incr dir -8
				}
				incr dir $resincr
				if {$dir >= $start + 90} {
				    incr num_scans -1
				    set dir $start
				    set resincr 5
				}
			    }
			    set test_corner [rand 4]
			    while {$new_corner == $test_corner} {set test_corner [rand 4]}
			    set new_corner $test_corner
			    eval goto [lindex $corners $new_corner]
			    set start [lindex $cor_dir $new_corner]
			    set dam [damage]
			}
		    }
		}
	    }
	}

	interp alias {} ${robot}Run $::data($robot,interp) ${robot}Run

    }
}

proc sysScanner {robot} {
    if {($::tick > 0) &&
	($::data($robot,syscall,$::tick) eq \
	     $::data($robot,syscall,[- $::tick 1]))} {
	puts SCANNING
	set ::data($robot,sysreturn,$::tick) 500
    } else {
	puts scannerCharge
	set ::data($robot,sysreturn,$::tick) 600
    }
}

proc sysCannon {robot} {
    set ::data($robot,sysreturn,$::tick) 0
}

proc sysRand {robot} {
    rand [lindex $::data($robot,syscall,$::tick) 2]
}

proc sysDrive {robot} {
    set ::data($robot,drive) \
	[list [lindex $::data($robot,syscall,$::tick) 1] \
		   [lindex $::data($robot,syscall,$::tick) 2]]

    set ::data($robot,sysreturn,$::tick) $::data($robot,drive)

}

proc sysLoc_x {robot} {
    set ::data($robot,sysreturn,$::tick) $::data($robot,x)
}

proc sysLoc_y {robot} {
    set ::data($robot,sysreturn,$::tick) $::data($robot,y)
}

proc move {robot} {
    if 0 {
    set d1  [expr ($r(hdg)-$deg+360)%360]
    set d2  [expr ($deg-$r(hdg)+360)%360]
    set d   [expr $d1<$d2?$d1:$d2]
    
    set r(dhdg)   $deg
    set r(dspeed) [expr $r(hflag) && $spd>$parms(heatsp) ? $parms(heatsp) : $spd]
    
    # shutdown drive if turning too fast at current speed
    set idx [expr int($d/25)] 
    if {$idx>3} {set idx 3}
    if {$r(speed)>$parms(turn,$idx)} {
	set r(dspeed) 0 
	set r(dhdg) $r(hdg)
    } else {
	set r(orgx)  $r(x)
	set r(orgy)  $r(y)
    set r(range) 0
    }
    # find direction of turn
    if {($r(hdg)+$d+360)%360==$deg} {
	set r(dir) +
    } else {
	set r(dir) -
    }
  append r(syscall) " ($r(dspeed))"
    return $r(dspeed) 
    }

    puts "$robot loc: $::data($robot,x) $::data($robot,y)"
}

proc act {} {
    foreach robot $::robots {
	set currentSyscall $::data($robot,syscall,$::tick)
	puts "currentSyscall: $currentSyscall"
	switch [lindex $currentSyscall 0] {
	    scanner {sysScanner $robot}
	    cannon  {sysCannon  $robot}
	    drive   {sysDrive   $robot}
	    loc_x   {sysLoc_x   $robot}
	    loc_y   {sysLoc_y   $robot}
	}
	move $robot
    }
}

proc tick {} {
    incr ::tick
    puts "tick: $::tick\n"
}

proc main {} {
    init
    act
    tick

    for {set i 0} {$i < 20} {incr i} {
	foreach robot $::robots {
	    ${robot}Run $::data($robot,sysreturn,[- $::tick 1])
	}
	act
	tick
    }
}
main
