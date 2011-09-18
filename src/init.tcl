#****F* init/file_header
#
# NAME
#
#   init.tcl
#
# DESCRIPTION
#
#   This file contains the initialisation procs.
#
#   The authors are Jonas Ferry, Peter Spjuth and Martin Lindskog, based
#   on TclRobots 2.0 by Tom Poindexter.
#
#   See http://tclrobots.org for more information.
#
# COPYRIGHT
#
#   Jonas Ferry (jonas.ferry@tclrobots.org), 2010. Licensed under the
#   Simplified BSD License. See LICENSE file for details.
#
#******

#****P* init/init_game
#
# NAME
#
#   init_game
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_game {} {
    global finish robmsg_out tick

    set finish ""
    set robmsg_out ""
    set tick 0
	
    init_parms
    init_trig_tables
    init_rand
    init_files
}
#******

#****P* init_game/init_parms
#
# NAME
#
#   init_parms
#
# DESCRIPTION
#
#   Set general TclRobots environment parameters.
#
# SOURCE
#
proc init_parms {} {
    global game gui parms

    # milliseconds per tick
    if {$gui} {
        set parms(tick) 100
    } else {
        set parms(tick) 0
    }
    # meters of possible error on scan resolution
    set parms(errdist) 10
    # distance traveled at 100% per tick
    set parms(sp) 10
    # accel/deaccel speed per tick as % speed
    set parms(accel) 10
    # maximum range for a missile
    set parms(mismax) 700
    # distance missiles travel per tick
    set parms(msp) 100
    # missile reload time in ticks
    set parms(mreload) [round [+ [/ $parms(mismax) $parms(msp)] 0.5]]
    # missile long reload time after clip
    set parms(lreload) [* $parms(mreload) 3]
    # number of missiles per clip
    set parms(clip)	4
    # max turn speed < 25 deg. delta
    set parms(turn,0) 100
    #  "   "     "   " 50  "     "
    set parms(turn,1) 50
    #  "   "     "   " 75  "     "
    set parms(turn,2) 30
    #  "   "     "   > 75  "     "
    set parms(turn,3) 20
    # max rate of turn per tick at speed < 25
    set parms(rate,0) 90
    #  "   "   "   "    "   "   "    "   " 50
    set parms(rate,1) 60
    #  "   "   "   "    "   "   "    "   " 75
    set parms(rate,2) 40
    #  "   "   "   "    "   "   "    "   > 75
    set parms(rate,3) 30
    #  "   "   "   "    "   "   "    "   > 75
    set parms(rate,4) 20
    # robot start health
    if {$game(debug)} {
        # Debug health for quick matches
        set parms(health) 1
    } else {
        # Normal health
        set parms(health) 100
    }
    # diameter of direct missile damage
    set parms(dia0) 6
    #     "    "  maximum   "      "
    set parms(dia1) 10
    #     "    "  medium    "      "
    set parms(dia2) 20
    #     "    "  minimum   "      "
    set parms(dia3) 40
    # damage within range 0
    set parms(hit0) -25
    #    "       "     "   1
    set parms(hit1) -12
    #    "       "     "   2
    set parms(hit2) -7
    #    "       "     "   3
    set parms(hit3) -3
    #    "    from collision into wall
    set parms(coll) -5
    # speed when heat builds
    set parms(heatsp) 35
    # max heat index, sets speed to heatsp
    set parms(heatmax) 200
    # inverse heating rate (greater hrate=slower)
    set parms(hrate) 10
    # cooling rate per tick, after overheat
    set parms(cooling) -25
    # cannon heating rate per shell
    set parms(canheat) 20
    # cannon cooling rate per tick
    set parms(cancool) -1
    # cannon heat index where scanner is inop
    set parms(scanbad) 35
    # quadrants, can be used to spread out robots at start
    set parms(quads) {{100 100} {600 100} {100 600} {600 600}}
}
#******

#****P* init_game/init_trig_tables
#
# NAME
#
#   init_trig_tables
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_trig_tables {} {
    global c_tab s_tab
    # init sin & cos tables
    set pi  [* 4 [atan 1]]
    set d2r [/ 180 $pi]

    for {set i 0} {$i<360} {incr i} {
        set s_tab($i) [sin [/ $i $d2r]]
        set c_tab($i) [cos [/ $i $d2r]]
    }
}
#******

#****P* init_game/init_rand
#
# NAME
#
#   init_rand
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_rand {} {
    global game

    # Set random seed.
    if {![info exists game(seed_arg)]} {
	set game(seed) [int [* [rand] [clock clicks]]]
    } else {
        set game(seed) $game(seed_arg)
    }
    srand $game(seed)
}
#******

#****P* init_game/init_files
#
# NAME
#
#   init_files
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_files {} {
    global activeRobots allRobots data game 

    set allRobots {}
    array unset data

    # Pick a random element from a list; use this for reading code!
    # lpick list {lindex $list [expr {int(rand()*[llength $list])}]}

    for {set i 0} {$i < [llength $game(robotfiles)]} {incr i} {
        # Give the robots names like r0, r1, etc.
        set robot r$i
        # Update list of robots
        lappend allRobots $robot

        # Read code
        set f [open [lindex $game(robotfiles) $i]]
        set data($robot,code) [read $f]
        close $f

    }
    set allSigs {}
    set file_index 0

    foreach robot $allRobots {
        set name [file tail [lindex $game(robotfiles) $file_index]]

        # Search for duplicate robot names
        foreach used_name [array names data *,name] {
            if {$name eq $data($used_name)} {
		set name "$data($used_name)([+ $file_index 1])"
            }
        }
        incr file_index

        # generate a new unique signature
        set newsig [mrand 65535]
        while {$newsig in $allSigs} {
            set newsig [mrand 65535]
        }
        lappend allSigs $newsig

        # window name = source.file_randnumber
        set data($robot,name) ${name}
        # the rand number as digital signature
        set data($robot,num) $newsig
    }
    # At the start of the game all robots are active
    set activeRobots $allRobots
}
#******

#****P* init/init_match
#
# NAME
#
#   init_match
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_match {} {
    init_robots
    init_interps
}
#******

#****P* init_match/init_robots
#
# NAME
#
#   init_robots
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_robots {} {
    global allRobots data parms 

    foreach robot $allRobots {
        set x [mrand 1000]
        set y [mrand 1000]

        #########
        # set robot parms
        #########
        # robot status: 0=not used or dead, 1=running
        set data($robot,status)	1
        # robot current x
        set data($robot,x) $x
        # robot current y
        set data($robot,y) $y
        # robot origin  x since last heading
        set data($robot,orgx) $x
        # robot origin  y   "    "     "
        set data($robot,orgy) $y
        # robot current range on this heading
        set data($robot,range) 0
        # robot current health
        set data($robot,health) $parms(health)
        # robot inflicted damage
        set data($robot,inflicted) 0
        # robot current speed
        set data($robot,speed) 0
        # robot desired   "
        set data($robot,dspeed)	0
        # robot current heading
        set data($robot,hdg) [mrand 360]
        # robot desired   "
        set data($robot,dhdg) $data($robot,hdg)
        # robot direction of turn (+/-)
        set data($robot,dir) +
        # robot last scan dsp signature
        set data($robot,sig) "0 0"
        # missile state: 0=avail, 1=flying
        set data($robot,mstate) 0
        # missile reload time: 0=ok, >0 = reloading
        set data($robot,reload) 0
        # number of missiles used per clip
        set data($robot,mused) 0
        # missile current x
        set data($robot,mx) 0
        # missile current y
        set data($robot,my) 0
        # missile origin  x
        set data($robot,morgx) 0
        # missile origin  y
        set data($robot,morgy) 0
        # missile heading
        set data($robot,mhdg) 0
        # missile current range
        set data($robot,mrange)	0
        # missile target distance
        set data($robot,mdist) 0
        # motor heat index
        set data($robot,heat) 0
        # overheated flag
        set data($robot,hflag) 0
        # alert procedure to call when scanned
        set data($robot,alert) {}
        # signature of last robot to scan us
        set data($robot,ping) {}
        # list of requested timed callbacks
        set data($robot,callbacks) {}
        # declared team
        set data($robot,team) ""
        # last team message sent
        set data($robot,data) ""
        # barrel temp, affected by cannon fire
        set data($robot,btemp) 0
        # request from robot slave interp to master
        # tick -1 is set to {} to handle scanner charging in tick 0
        set data($robot,syscall,-1) {}
        # return value from master to slave interp
        set data($robot,sysreturn,0) {}
    }
}
#******

#****P* init_match/init_interps
#
# NAME
#
#   init_interps
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc init_interps {} {
    global allRobots data thisDir tick

    set tick 0
    foreach robot $allRobots {
        set data($robot,interp) [interp create -safe]

        # Stop robots from using another rand than the syscall
        $data($robot,interp) eval {rename tcl::mathfunc::rand {}}

        interp alias $data($robot,interp) syscall {} syscall $robot

        $data($robot,interp) invokehidden source \
	    [file join $thisDir syscalls.tcl]

        $data($robot,interp) eval coroutine \
                ${robot}Run [list uplevel \#0 $data($robot,code)]

        interp alias {} ${robot}Run $data($robot,interp) ${robot}Run
    }
    act
    tick
}
#******
