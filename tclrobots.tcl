namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::*

#########
# set general tclrobots environment parameters
#########
# number milliseconds robots wait on sys call
set ::parms(do_wait) 100
# millisecond tick  
set ::parms(tick)	500
# simulation clock tick
set ::parms(simtick) 500
# meters of possible error on scan resolution
set ::parms(errdist) 10
# distance traveled at 100% per tick
set ::parms(sp) 10
# accel/deaccel speed per tick as % speed 
set ::parms(accel) 10
# maximum range for a missile
set ::parms(mismax) 700
# distance missiles travel per tick
set ::parms(msp) 100
# missile reload time in ticks
set ::parms(mreload) [expr round(($parms(mismax)/$parms(msp))+0.5)]
# missile long reload time after clip
set ::parms(lreload) [expr $parms(mreload)*3]
# number of missiles per clip
set ::parms(clip)	4
# max turn speed < 25 deg. delta
set ::parms(turn,0) 100
#  "   "     "   " 50  "     "
set ::parms(turn,1) 50
#  "   "     "   " 75  "     "
set ::parms(turn,2) 30
#  "   "     "   > 75  "     "
set ::parms(turn,3) 20
# max rate of turn per tick at speed < 25
set ::parms(rate,0) 90
#  "   "   "   "    "   "   "    "   " 50
set ::parms(rate,1) 60
#  "   "   "   "    "   "   "    "   " 75
set ::parms(rate,2) 40
#  "   "   "   "    "   "   "    "   > 75
set ::parms(rate,3) 30
#  "   "   "   "    "   "   "    "   > 75
set ::parms(rate,4) 20
# diameter of direct missile damage
set ::parms(dia0) 6
#     "    "  maximum   "      "
set ::parms(dia1) 10
#     "    "  medium    "      "
set ::parms(dia2) 20
#     "    "  minimum   "      "   
set ::parms(dia3) 40
# %damage within range 0
set ::parms(hit0) 25
#    "       "     "   1
set ::parms(hit1) 12
#    "       "     "   2
set ::parms(hit2) 7
#    "       "     "   3
set ::parms(hit3) 3
#    "    from collision into wall 
set ::parms(coll) 5
# %speed when heat builds
set ::parms(heatsp) 35
# max heat index, sets speed to heatsp
set ::parms(heatmax) 200
# inverse heating rate (greater hrate=slower)
set ::parms(hrate) 10
# cooling rate per tick, after overheat
set ::parms(cooling) -25
# cannon heating rate per shell
set ::parms(canheat) 20
# cannon cooling rate per tick
set ::parms(cancool) -1
# cannon heat index where scanner is inop
set ::parms(scanbad) 35

set outfile ""

# init sin & cos tables
set pi  [expr 4*atan(1)]
set d2r [expr 180/$pi]

for {set i 0} {$i<360} {incr i} {
    set ::s_tab($i) [expr sin($i/$d2r)]
    set ::c_tab($i) [expr cos($i/$d2r)]
}


# Pick a random element from a list
# lpick list {lindex $list [expr {int(rand()*[llength $list])}]}

# Set random seed
srand [expr ([pid]*[file atime /dev/tty])%65536]

# Return random integer 1-max
proc rand {max} {
    return [expr {int(rand()*$max) + 1}]
}

# Handle syscalls from robots
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
#    set ::data($robot,drive) \
#	[list [lindex $::data($robot,syscall,$::tick) 1] \
#		   [lindex $::data($robot,syscall,$::tick) 2]]

#    set ::data($robot,sysreturn,$::tick) $::data($robot,drive)

    set deg [lindex $::data($robot,syscall,$::tick) 1]
    set spd [lindex $::data($robot,syscall,$::tick) 2]
    
    set d1  [expr ($::data($robot,hdg)-$deg+360)%360]
    set d2  [expr ($deg-$::data($robot,hdg)+360)%360]
    set d   [expr $d1<$d2?$d1:$d2]
    
    set ::data($robot,dhdg)   $deg
    set ::data($robot,dspeed) \
	[expr $::data($robot,hflag) && \
	     $spd>$::parms(heatsp) ? $::parms(heatsp) : $spd]
    
    # shutdown drive if turning too fast at current speed
    set idx [expr int($d/25)] 
    if {$idx>3} {set idx 3}
    if {$::data($robot,speed)>$::parms(turn,$idx)} {
	set ::data($robot,dspeed) 0 
	set ::data($robot,dhdg) $::data($robot,hdg)
    } else {
	set ::data($robot,orgx)  $::data($robot,x)
	set ::data($robot,orgy)  $::data($robot,y)
	set ::data($robot,range) 0
    }
    # find direction of turn
    if {($::data($robot,hdg)+$d+360)%360==$deg} {
	set ::data($robot,dir) +
    } else {
	set ::data($robot,dir) -
    }
    
    set ::data($robot,sysreturn,$::tick) $::data($robot,dspeed)

    puts "$robot drive: $::data($robot,dir) $::data($robot,speed)"


}

proc sysLoc_x {robot} {
    set ::data($robot,sysreturn,$::tick) $::data($robot,x)
}

proc sysLoc_y {robot} {
    set ::data($robot,sysreturn,$::tick) $::data($robot,y)
}

proc initRobots {} {
    set ::robots {r1}

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

	if {$robot eq "r1"} {
	    set ::data($robot,code) \
		[read [open ../tclrobots-2.0/samples/charger.tr]]
	}

	$::data($robot,interp) eval coroutine \
	    ${robot}Run [list apply [list {} $::data($robot,code)]]

	interp alias {} ${robot}Run $::data($robot,interp) ${robot}Run

    }
}

#########
# update position of missiles and robots, assess damage
#########
proc updateRobots {} {
  set num_miss 0
#  set num_rob  0
    foreach robot $::robots {
	# check all flying missiles
	if {$::data($robot,mstate)} {
	    incr num_miss 
	    # update location of missile
	    set ::data($robot,mrange) \
		[expr $::data($robot,mrange)+$::parms(msp)]
	    set ::data($robot,mx) \
		[expr ($::c_tab($::data($robot,mhdg))*$::data($robot,mrange))+\
		     $::data($robot,morgx)]
	    set ::data($robot,my) \
		[expr ($::s_tab($::data($robot,mhdg))*$::data($robot,mrange))+\
		     $::data($robot,morgy)]
	    # check if missile reached target
	    if {$::data($robot,mrange) > $::data($robot,mdist)} {
		set ::data($robot,mstate) 0
		set ::data($robot,mx) \
		    [expr ($::c_tab($::data($robot,mhdg))*\
			       $::data($robot,mdist))+$::data($robot,morgx)]
		set ::data($robot,my) \
		    [expr ($::s_tab($::data($robot,mhdg))*\
			       $::data($robot,mdist))+$::data($robot,morgy)]
		after 1 "show_explode $robot"
		
		# assign damage to all within explosion ranges
		foreach robot $::robots {
		    if {!$::data($robot,status)} {continue}
		    set d [expr hypot($::data($robot,mx)-$::data($robot,x),\
					  $::data($robot,my)-\
					  $::data($robot,y))]
		    if {$d<$::parms(dia3)} {
			if {$d<$::parms(dia0)} {
			    incr ::data($robot,damage) $::parms(hit0)
			} elseif {$d<$::parms(dia1)} {
			    incr ::data($robot,damage) $::parms(hit1)
			} elseif {$d<$::parms(dia2)} {
			    incr ::data($robot,damage) $::parms(hit2)
			} else {
			    incr ::data($robot,damage) $::parms(hit3)
			}
			up_damage $robot $::data($robot,damage)
		    }
		}
	    }
	}
	
	# skip rest if robot dead
	if {!$::data($robot,status)} {continue}
	
	# update missile reloader
	if {$::data($robot,reload)} {incr ::data($robot,reload) -1}
	
	# check for excessive speed, increment heat 
	if {$::data($robot,speed) > $::parms(heatsp)} {
	    incr ::data($robot,heat) [expr round(($::data($robot,speed)-$::parms(heatsp))/$::parms(hrate))+1]
	    if {$::data($robot,heat) >= $::parms(heatmax)} {
		set ::data($robot,heat) $::parms(heatmax)
		set ::data($robot,hflag) 1
		if {$::data($robot,dspeed) > $::parms(heatsp)} {
		    set ::data($robot,dspeed) $::parms(heatsp)
		}
	    }
	} else {
	    # if overheating, apply cooling rate
	    if {$::data($robot,hflag) || $::data($robot,heat) > 0} {
		incr ::data($robot,heat) $::parms(cooling)
		if {$::data($robot,heat) <= 0} { set ::data($robot,hflag) 0; set ::data($robot,heat) 0 }
	    }
	}
	
	# check for barrel overheat, apply cooling
	if {$::data($robot,btemp)} {
	    incr ::data($robot,btemp) $::parms(cancool)
	    if {$::data($robot,btemp) < 0} { set ::data($robot,btemp) 0 }
	}
	
	# update robot speed, moderated by acceleration
	if {$::data($robot,speed) != $::data($robot,dspeed)} {
	    if {$::data($robot,speed) > $::data($robot,dspeed)} {
		incr ::data($robot,speed) -$::parms(accel)
		if {$::data($robot,speed) < $::data($robot,dspeed)} {
		    set ::data($robot,speed) $::data($robot,dspeed)
		}
	    } else {
		incr ::data($robot,speed) $::parms(accel)
		if {$::data($robot,speed) > $::data($robot,dspeed)} {
		    set ::data($robot,speed) $::data($robot,dspeed)
		}
	    }
	}
	
	# update robot heading, moderated by turn rates
	if {$::data($robot,hdg) != $::data($robot,dhdg)} {
	    set mrate $::parms(rate,[expr int($::data($robot,speed)/25)])
	    set d1 [expr ($::data($robot,dhdg)-$::data($robot,hdg)+360)%360]
	    set d2 [expr ($::data($robot,hdg)-$::data($robot,dhdg)+360)%360]
	    set d  [expr $d1<$d2?$d1:$d2]
	    if {$d<=$mrate} {
		set ::data($robot,hdg) $::data($robot,dhdg)
	    } else {
		set ::data($robot,hdg) [expr ($::data($robot,hdg)$::data($robot,dir)$mrate+360)%360]
	    }
	    set ::data($robot,orgx)  $::data($robot,x)
	    set ::data($robot,orgy)  $::data($robot,y)
	    set ::data($robot,range) 0
	}
	
	# update distance traveled on this heading
	if {$::data($robot,speed) > 0} {
	    set ::data($robot,range) [expr $::data($robot,range)+($::data($robot,speed)*$::parms(sp)/100)]
	    set ::data($robot,x)     [expr round(($::c_tab($::data($robot,hdg))*$::data($robot,range))+$::data($robot,orgx))]
	    set ::data($robot,y)     [expr round(($::s_tab($::data($robot,hdg))*$::data($robot,range))+$::data($robot,orgy))]
	    # check for wall collision
	    if {$::data($robot,x)<0 || $::data($robot,x)>999} {
		set ::data($robot,x) [expr $::data($robot,x)<0? 0 : 999]
		set ::data($robot,orgx)   $::data($robot,x)
		set ::data($robot,orgy)   $::data($robot,y)
		set ::data($robot,range)  0
		set ::data($robot,speed)  0
		set ::data($robot,dspeed) 0
		incr ::data($robot,damage) $::parms(coll)
		up_damage $robot $::data($robot,damage)
	    }
	    if {$::data($robot,y)<0 || $::data($robot,y)>999} {
		set ::data($robot,y) [expr $::data($robot,y)<0? 0 : 999]
		set ::data($robot,orgx)   $::data($robot,x)
		set ::data($robot,orgy)   $::data($robot,y)
		set ::data($robot,range)  0
		set ::data($robot,speed)  0
		set ::data($robot,dspeed) 0
		incr ::data($robot,damage) $::parms(coll)
		up_damage $robot $::data($robot,damage)
	    }
	}
    }

    # check for robot health
    set diffteam ""
    set num_team 0
    foreach robot $::robots {
	upvar #0 $robot r
	if {$::data($robot,status)} {
	    if {$::data($robot,damage)>=100} {
		set ::data($robot,status) 0
		set ::data($robot,damage) 100
		up_damage $robot $::data($robot,damage)
		disable_robot $robot 1
		append finish "$::data($robot,name) team($::data($robot,team)) dead at tick: $ticks\n"
	    } else {
		incr num_rob
		if {$::data($robot,team) != ""} {
		    if {[lsearch -exact $diffteam $::data($robot,team)] == -1} {
			lappend diffteam $::data($robot,team)
			incr num_team
		    }
		} else {
		    lappend diffteam $::data($robot,name)
		    incr num_team
		}
	    }
	}
    }
    
    if {($num_rob<=1 || $num_team==1) && $num_miss==0} {
	set running 0
    }
    after 1 show_robots
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
    }
}

proc tick {} {
    incr ::tick
    puts "tick: $::tick\n"
}

proc runRobots {} {
    set i 1
    while {$i < 20} {
	puts "i: $i"
	foreach robot $::robots {
	    ${robot}Run $::data($robot,sysreturn,[- $::tick 1])
	}
	act
	updateRobots
	puts "loc: $::data(r1,x) $::data(r1,y)"
	tick
	incr i
	after 0 [info coroutine] yield
    }
}



proc init {} {
    puts init
    initRobots
    act
    tick
}

proc main {} {
    set ::tick 0
    init
    coroutine runRobotsCo runRobots
}
main
