namespace import ::tcl::mathop::*
namespace import ::tcl::mathfunc::*
set ::thisScript [file join [pwd] [info script]]
set ::thisDir [file dirname $::thisScript]

#########
# set general tclrobots environment parameters
#########
# milliseconds per tick
set ::parms(tick) 100
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
# robot start health
#set ::parms(health) 100
set ::parms(health) 100; #for debugging
# diameter of direct missile damage
set ::parms(dia0) 6
#     "    "  maximum   "      "
set ::parms(dia1) 10
#     "    "  medium    "      "
set ::parms(dia2) 20
#     "    "  minimum   "      "
set ::parms(dia3) 40
# damage within range 0
set ::parms(hit0) -25
#    "       "     "   1
set ::parms(hit1) -12
#    "       "     "   2
set ::parms(hit2) -7
#    "       "     "   3
set ::parms(hit3) -3
#    "    from collision into wall
set ::parms(coll) -5
# speed when heat builds
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

set ::parms(quads)  {{100 100} {600 100} {100 600} {600 600}}
set ::parms(shapes) {{3 12 7} {8 12 5} {11 11 3} {12 8 4}}

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
set ::seed [expr ([pid]*[file atime /dev/tty])]
srand $::seed

# Return random integer 1-max
proc rand {max} {
    return [expr {int(rand()*$max)}]
}

# Handle syscalls from robots
proc syscall {args} {
    set robot [lindex $args 0]
    set result 0

    #puts "args: $args"

    set syscall [lrange $args 1 end]
    #puts "Syscall $robot: $syscall"

    if {[lindex $syscall 0] eq "dputs"} {
        set msg [lrange $args 2 end]
        if {$::gui} {
            # Output to robot message box
            show_msg $robot $msg
            # Output to terminal for debugging
            puts "$robot: $msg ($::tick)"
        } else {
            # Output to terminal
            puts "$robot: $msg"
        }
    } elseif {[lindex $syscall 0] eq "rand"} {
        set result [rand [lindex $syscall 1]]
    } else {
        set ::data($robot,syscall,$::tick) $syscall
    }
    return $result
}

proc sysScanner {robot} {

    if {($::data($robot,syscall,$::tick) eq \
             $::data($robot,syscall,[- $::tick 1]))} {

        set deg [lindex $::data($robot,syscall,$::tick) 1]
        set res [lindex $::data($robot,syscall,$::tick) 2]

        set dsp    0
        set health 0
        set near   9999
        foreach target $::activeRobots {
            if {"$target" == "$robot"} { continue }
            set x [expr $::data($target,x)-$::data($robot,x)]
            set y [expr $::data($target,y)-$::data($robot,y)]
            set d [expr round(57.2958*atan2($y,$x))]
            if {$d<0} {incr d 360}
            set d1  [expr ($d-$deg+360)%360]
            set d2  [expr ($deg-$d+360)%360]
            set f   [expr $d1<$d2?$d1:$d2]
            if {$f<=$res} {
                set ::data($target,ping) $::data($robot,num)
                set dist [expr round(hypot($x,$y))]
                if {$dist<$near} {
                    set derr [expr $::parms(errdist)*$res]
                    set terr [expr ($res>0 ? 5 : 0) + [rand $derr]]
                    set fud1  [expr [rand 2] ? \"-\" : \"+\"]
                    set fud2  [expr [rand 2] ? \"-\" : \"+\"]
                    set near [expr $dist $fud1 $terr $fud2 \
                                  $::data($robot,btemp)]
                    if {$near<1} {set near 1}
                    set dsp    $::data($robot,num)
                    set health $::data($robot,health)
                }
            }
        }
        # if cannon has overheated scanner, report 0
        if {$::data($robot,btemp) >= $::parms(scanbad)} {
            set ::data($robot,sig) "0 0"
            set val 0
        } else {
            set ::data($robot,sig) "$dsp $health"
            set val [expr $near==9999?0:$near]
        }
        set ::data($robot,sysreturn,$::tick) $val

    } else {
        set ::data($robot,sysreturn,$::tick) 0
    }
}

proc sysDsp {robot} {
    set ::data($robot,sysreturn,$::tick) $::data($robot,sig)
}

proc sysAlert {robot} {
#    set alertproc ${robot}alert
#    interp alias {} $alertproc $::data($robot,interp) \
#        [lindex $::data($robot,syscall,$::tick) 1]
    set ::data($robot,alert) [lindex $::data($robot,syscall,$::tick) 1]
    set ::data($robot,sysreturn,$::tick) 1
}

proc sysCannon {robot} {
    set deg [lindex $::data($robot,syscall,$::tick) 1]
    set rng [lindex $::data($robot,syscall,$::tick) 2]

    set val 0

    if {$::data($robot,mstate)} {
        set val 0
    } elseif {$::data($robot,reload)} {
        set val 0
    } elseif [catch {set deg [expr round($deg)]}] {
        set val -1
    } elseif [catch {set rng [expr round($rng)]}] {
        set val -1
    } elseif {($deg<0 || $deg>359)} {
        set val -1
    } elseif {($rng<0 || $rng>$::parms(mismax))} {
        set val -1
    } else {
        set ::data($robot,mhdg)   $deg
        set ::data($robot,mdist)  $rng
        set ::data($robot,mrange) 0
        set ::data($robot,mstate) 1
        set ::data($robot,morgx)  $::data($robot,x)
        set ::data($robot,morgy)  $::data($robot,y)
        set ::data($robot,mx)     $::data($robot,x)
        set ::data($robot,my)     $::data($robot,y)
        incr ::data($robot,btemp) $::parms(canheat)
        incr ::data($robot,mused)
        # set longer reload time if used all missiles in clip
        if {$::data($robot,mused) == $::parms(clip)} {
            set ::data($robot,reload) $::parms(lreload)
            set ::data($robot,mused) 0
        } else {
            set ::data($robot,reload) $::parms(mreload)
        }
        set val 1
    }
    set ::data($robot,sysreturn,$::tick) $val
}

proc sysDrive {robot} {
    set deg [lindex $::data($robot,syscall,$::tick) 1]
    set spd [lindex $::data($robot,syscall,$::tick) 2]

    set d1  [expr ($::data($robot,hdg)-$deg+360)%360]
    set d2  [expr ($deg-$::data($robot,hdg)+360)%360]
    set d   [expr $d1<$d2?$d1:$d2]

    set ::data($robot,dhdg) $deg
    set ::data($robot,dspeed) \
	[expr $::data($robot,hflag) && \
	     $spd>$::parms(heatsp) ? $::parms(heatsp) : $spd]

    # shutdown drive if turning too fast at current speed
    set index [expr int($d/25)]
    if {$index>3} {set index 3}
    if {$::data($robot,speed)>$::parms(turn,$index)} {
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
}

proc sysData {robot} {
    set val 0

    switch $::data($robot,syscall,$::tick) {
        health {set val $::data($robot,health)}
        speed  {set val $::data($robot,speed)}
        heat   {set val $::data($robot,heat)}
        loc_x  {set val $::data($robot,x)}
        loc_y  {set val $::data($robot,y)}
    }
    set ::data($robot,sysreturn,$::tick) $val
}

proc sysTick {robot} {
    set ::data($robot,sysreturn,$::tick) $::tick
}

proc init_robots {} {
    set file_index 0
    foreach robot $::allRobots {
        set ::data($robot,interp) [interp create -safe]

        set name [file tail [lindex $::robotFiles $file_index]]
        incr file_index
        #set name $robot

        set x [rand 1000]
        set y [rand 1000]

        # generate a new signature
        set newsig [rand 65535]

        #########
        # set robot parms
        #########
        # window name = source.file_randnumber
        set ::data($robot,name) ${name}
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
        # robot current health
        set ::data($robot,health) $::parms(health)
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
        # alert procedure to call when scanned
        set ::data($robot,alert) {}
        # signature of last robot to scan us
        set ::data($robot,ping) {}
        # declared team
        set ::data($robot,team) ""
        # last team message sent
        set ::data($robot,data) ""
        # barrel temp, affected by cannon fire
        set ::data($robot,btemp) 0
        # request from robot slave interp to master
        # tick -1 is set to {} to handle scanner charging in tick 0
        set ::data($robot,syscall,-1) {}
        # return value from master to slave interp
        set ::data($robot,sysreturn,0) {}

        interp alias $::data($robot,interp) syscall {} syscall $robot

        $::data($robot,interp) invokehidden source $::thisDir/syscalls.tcl

        $::data($robot,interp) eval coroutine \
                ${robot}Run [list uplevel \#0 $::data($robot,code)]

        interp alias {} ${robot}Run $::data($robot,interp) ${robot}Run
    }
}

#########
# Disable robot
#########
proc disable_robot {robot} {
    interp delete $::data($robot,interp)
    set index [lsearch -exact $::activeRobots $robot]
    set ::activeRobots [lreplace $::activeRobots $index $index]
    set ::data($robot,syscall,$::tick) {}
}


###############################################################################
#
# update damage label of robot
#
#

proc up_damage {robot} {
#    if {$::data($robot,damage) >= 100} {
#        set ::data($robot,damage) dead
#        
#}
}

#########
# update position of missiles and robots, assess damage
#########
proc update_robots {} {
    global allRobots data

    foreach robot $allRobots {
        # check all flying missiles
        set num_miss [check_missiles $robot]

        # skip rest if robot dead
        if {!$data($robot,status)} {continue}

        # update missile reloader
        if {$data($robot,reload)} {incr data($robot,reload) -1}

        # check for barrel overheat, apply cooling
        check_barrel $robot

        # check for excessive speed, increment heat
        check_speed $robot

        # update robot speed, moderated by acceleration
        update_speed $robot

        # update robot heading, moderated by turn rates
        update_heading $robot

        # update distance traveled on this heading
        update_distance $robot

        # check for wall collision
        check_wall $robot
    }
    # check for robot health
    set health_status [check_health]

    set num_rob       [lindex $health_status 0]
    set diffteam      [lindex $health_status 1]
    set num_team      [lindex $health_status 2]

    if {($num_rob<=1 || $num_team==1) && $num_miss==0} {
        # Stop game
        set ::running 0
    }
}

proc check_missiles {robot} {
    # check all flying missiles
    # used by update_robots
    global data activeRobots
    set num_miss 0

    if {$data($robot,mstate)} {
        incr num_miss
        update_missile_location $robot
        # check if missile reached target
        if {$data($robot,mrange) > $data($robot,mdist)} {
            missile_reached_target $robot

            # assign damage to all within explosion ranges
            foreach target $activeRobots {
                if {!$data($target,status)} {continue}
                assign_missile_damage $robot $target
            }
        }
    }
    return $num_miss
}

proc update_missile_location {robot} {
    # update location of missile
    # used by update_robots
    global data parms c_tab s_tab

    set data($robot,mrange) \
        [expr $data($robot,mrange)+$parms(msp)]
    set data($robot,mx) \
        [expr ($c_tab($data($robot,mhdg))*\
                   $data($robot,mrange))+\
             $data($robot,morgx)]
    set data($robot,my) \
        [expr ($s_tab($data($robot,mhdg))*\
                   $data($robot,mrange))+\
             $data($robot,morgy)]
}

proc missile_reached_target {robot} {
    # used by update_robots
    global data gui c_tab s_tab

    set data($robot,mstate) 0
    set data($robot,mx) \
        [expr ($c_tab($data($robot,mhdg))*\
                   $data($robot,mdist))+\
             $data($robot,morgx)]
    set data($robot,my) \
        [expr ($s_tab($data($robot,mhdg))*\
                   $data($robot,mdist))+\
             $data($robot,morgy)]
    if {$gui} {
        after 1 "show_explode $robot"
    }
}

proc assign_missile_damage {robot target} {
    # assign damage to all within explosion ranges
    # used by update_robots
    global data parms

    set d [expr hypot($data($robot,mx)-$data($target,x),\
                          $data($robot,my)-\
                          $data($target,y))]
    if {$d<$parms(dia3)} {
        if {$d<$parms(dia0)} {
            incr data($target,health) $parms(hit0)
        } elseif {$d<$parms(dia1)} {
            incr data($target,health) $parms(hit1)
        } elseif {$d<$parms(dia2)} {
            incr data($target,health) $parms(hit2)
        } else {
            incr data($target,health) $parms(hit3)
        }
        up_damage $target
    }
}

proc check_barrel {robot} {
    # check for barrel overheat, apply cooling
    # used by update_robots
    global data parms

    if {$data($robot,btemp)} {
        incr data($robot,btemp) $parms(cancool)
        if {$data($robot,btemp) < 0} {
            set data($robot,btemp) 0
        }
    }
}

proc check_speed {robot} {
    # check for excessive speed, increment heat
    # used by update_robots
    global data parms

    if {$data($robot,speed) > $parms(heatsp)} {
        incr data($robot,heat) \
            [expr round(($data($robot,speed)-\
                             $parms(heatsp))/$parms(hrate))+1]
        if {$data($robot,heat) >= $parms(heatmax)} {
            set data($robot,heat) $parms(heatmax)
            set data($robot,hflag) 1
            if {$data($robot,dspeed) > $parms(heatsp)} {
                set data($robot,dspeed) $parms(heatsp)
            }
        }
    } else {
        # if overheating, apply cooling rate
        if {$data($robot,hflag) || $data($robot,heat) > 0} {
            incr data($robot,heat) $parms(cooling)
            if {$data($robot,heat) <= 0} {
                set data($robot,hflag) 0
                set data($robot,heat) 0
            }
        }
    }
}

proc update_speed {robot} {
    # update robot speed, moderated by acceleration
    # used by update_robots
    global data parms

    if {$data($robot,speed) != $data($robot,dspeed)} {
        if {$data($robot,speed) > $data($robot,dspeed)} {
            incr data($robot,speed) -$parms(accel)
            if {$data($robot,speed) < $data($robot,dspeed)} {
                set data($robot,speed) $data($robot,dspeed)
            }
        } else {
            incr data($robot,speed) $parms(accel)
            if {$data($robot,speed) > $data($robot,dspeed)} {
                set data($robot,speed) $data($robot,dspeed)
            }
        }
    }
}

proc update_heading {robot} {
    # update robot heading, moderated by turn rates
    # used by update_robots
    global data parms

    if {$data($robot,hdg) != $data($robot,dhdg)} {
        set mrate $parms(rate,[expr int($data($robot,speed)/25)])
        set d1 [expr ($data($robot,dhdg)-$data($robot,hdg)+360)%360]
        set d2 [expr ($data($robot,hdg)-$data($robot,dhdg)+360)%360]
        set d  [expr $d1<$d2?$d1:$d2]
        if {$d<=$mrate} {
            set data($robot,hdg) $data($robot,dhdg)
        } else {
            set data($robot,hdg) \
                [expr ($data($robot,hdg)$data($robot,dir)$mrate+\
                           360)%360]
        }
        set data($robot,orgx)  $data($robot,x)
        set data($robot,orgy)  $data($robot,y)
        set data($robot,range) 0
    }
}

proc update_distance {robot} {
    # update distance traveled on this heading
    # used by update_robots
    global data parms c_tab s_tab

    if {$data($robot,speed) > 0} {
        set data($robot,range) \
            [+ $data($robot,range) \
                 [/ [* $data($robot,speed) $parms(sp)] 100]]

        # Modify range with random factor to avoid totally
        # deterministic movement. Range is currently +- 1%.
        # Playtesting will tell if this should be lower or higher.
        set randfactor [/ [+ [rand 100] 1.0] 10000]
        if {[rand 2] == 0} {
            set randfactor [- $randfactor]
        }
        set data($robot,range) [+ $data($robot,range) \
                                    [* $data($robot,range) \
                                         $randfactor]]

        set data($robot,x) \
            [expr round(($c_tab($data($robot,hdg))*\
                             $data($robot,range))+\
                            $data($robot,orgx))]
        set data($robot,y) \
            [expr round(($s_tab($data($robot,hdg))*\
                             $data($robot,range))+\
                            $data($robot,orgy))]
    }
}

proc check_wall {robot} {
    # check for wall collision
    # used by update_robots
    global data parms

    if {$data($robot,speed) > 0} {
        if {$data($robot,x)<0 || $data($robot,x)>999} {
            set data($robot,x) [expr $data($robot,x)<0? 0 : 999]
            set data($robot,orgx)   $data($robot,x)
            set data($robot,orgy)   $data($robot,y)
            set data($robot,range)  0
            set data($robot,speed)  0
            set data($robot,dspeed) 0
            incr data($robot,health) $parms(coll)
            up_damage $robot
            puts "WALL $robot: $data($robot,health)"
        }
        if {$data($robot,y)<0 || $data($robot,y)>999} {
            set data($robot,y) [expr $data($robot,y)<0? 0 : 999]
            set data($robot,orgx)   $data($robot,x)
            set data($robot,orgy)   $data($robot,y)
            set data($robot,range)  0
            set data($robot,speed)  0
            set data($robot,dspeed) 0
            incr data($robot,health) $parms(coll)
            up_damage $robot
        }
    }
}

proc check_health {} {
    # check for robot health
    global activeRobots data tick

    set num_rob  0
    set diffteam ""
    set num_team 0
    foreach robot $activeRobots {
        if {$data($robot,status)} {
            if {$data($robot,health) <= 0 } {
                set data($robot,status) 0
                set data($robot,health) 0
                up_damage     $robot
                disable_robot $robot
                append ::finish "$data($robot,name) team($data($robot,team)) dead at tick: $tick\n"
            } else {
                incr num_rob
                if {$data($robot,team) != ""} {
                    if {[lsearch -exact $diffteam $data($robot,team)] == -1} {
                        lappend diffteam $data($robot,team)
                        incr num_team
                    }
                } else {
                    lappend diffteam $data($robot,name)
                    incr num_team
                }
            }
        }
    }
    return $num_rob $diffteam $num_team
}

proc act {} {
    foreach robot $::activeRobots {
        if {$::data($robot,status)} {
            set currentSyscall $::data($robot,syscall,$::tick)
            switch [lindex $currentSyscall 0] {
                scanner {sysScanner $robot}
                dsp     {sysDsp     $robot}
                alert   {sysAlert   $robot}
                cannon  {sysCannon  $robot}
                drive   {sysDrive   $robot}
                health  -
                speed   -
                heat    -
                loc_x   -
                loc_y   {sysData    $robot}
                tick    {sysTick    $robot}
            }
        }
    }
}

proc tick {} {
    if {$::tick < $::max_ticks} {
        incr ::tick
    } else {
        set ::running 0
    }
}

proc runRobots {} {
    while {$::running == 1} {
        foreach robot $::activeRobots {
            if {($::data($robot,alert) ne {}) && \
                    ($::data($robot,ping) ne {})} {
                # Prepend alert data to sysreturn no notify robot it's
                # been scanned.
                set ::data($robot,sysreturn,[- $::tick 1]) \
                    "alert $::data($robot,alert) $::data($robot,ping) $::data($robot,sysreturn,[- $::tick 1])"

                # Robot is notified; reset alert request
                set ::data($robot,ping) {}
            }
            ${robot}Run $::data($robot,sysreturn,[- $::tick 1])
        }
        act

        update_robots

        if {$::gui} {
            update_gui
        }

        tick

        after $::parms(tick) [info coroutine]
        yield
    }
}

proc find_winner {} {
    set ::finish ""
    set alive 0
    set winner ""
    set num_team 0
    set diffteam ""
    set win_color black
    foreach robot $::activeRobots {
        disable_robot $robot
        incr alive
        lappend winner $::data($robot,name)
#        set win_color $::data($robot,color)
        if {$::data($robot,team) != ""} {
            if {[lsearch -exact $diffteam $::data($robot,team)] == -1} {
                lappend diffteam $::data($robot,team)
                incr num_team
            }
        } else {
            incr num_team
        }
    }
    
    switch $alive {
        0 {
            set ::win_msg "No robots left alive"
            puts $::win_msg
        }
        1 {
            if {[string length $diffteam] > 0} {
                set diffteam "Team $diffteam"
            }
            set ::win_msg "\nWinner!\n\n$diffteam\n$winner\n"
            puts $::win_msg
        }
        default {
            # check for teams
            if {$num_team == 1} {
                set ::win_msg "Winner!\n\nTeam $diffteam\n$winner"
                puts $::win_msg
            } else {
                set ::win_msg "Tie:\n\n$winner"
                puts $::win_msg
            }
        }
    }
    set ::win_msg2 [join [split $::win_msg \n] " "]
    set score "score: "
    set points 1
    foreach l [split $::finish \n] {
        set n [lindex $l 0]
        if {[string length $n] == 0} {continue}
        set l [string last _ $n]
        if {$l > 0} {incr l -1; set n [string range $n 0 $l]}
        append score "$n = $points  "
        incr points
    }
    foreach n $winner {
        set l [string last _ $n]
        if {$l > 0} {incr l -1; set n [string range $n 0 $l]}
        append score "$n = $points  "
    }
    catch {write_file $outfile \
               "$players\n$finish\n$::win_msg2\n\n$score\n\n\n"}
}

proc init {} {
    set ::tick 0

    set ::allRobots {}

    for {set i 0} {$i < [llength $::robotFiles]} {incr i} {
        # Give the robots names like r0, r1, etc.
        set robot r$i
        # Update list of robots
        lappend ::allRobots $robot
        # Read
        set f [open [lindex $::robotFiles $i]]
        set ::data($robot,code) [read $f]
        close $f
    }

    # At the start of the game all robots are active
    set ::activeRobots $::allRobots

    init_robots
    act
    tick
}

proc main {} {
    set ::running 1
    coroutine runRobotsCo runRobots
    vwait ::running
    puts "activerobots: $::activeRobots"
    find_winner
    puts "seed: $::seed"
}

#############################################################################
# do it!
# main line code

# check for command line args, run tournament if any 

set ::gui        0
set ::max_ticks  6000
set arg_tlimit   10
set arg_outfile  "results.out"
set ::robotFiles {}
set tourn_type   0
set ::numlist    0

foreach arg $::argv {
    switch -glob -- $arg  {
        -t*     {set ::tourn_type 1}
        default {
            if {[file isfile [pwd]/$arg]} {
                lappend ::robotFiles [pwd]/$arg
            } else {
                puts "'$arg' not found, skipping"
            }
        }
    }
}

if {[llength $::robotFiles] >= 2} {
    # Run batch
    set ::parms(tick) 0
    puts "Running time [/ [lindex [time {init;main}] 0] 1000000.0] seconds"
} else {
    # Run GUI
    set ::gui 1
    source $::thisDir/gui.tcl
    init_gui
}



if 0 {
# check for tournament, two or more files on command line
if {[llength $arg_files] >= 2} {
  # if not a one-on-one and 2 or more files, set battle match
  if {$tourn_type == 0} {
    set tourn_type 4
  }







  wm geom . +20+20
  if {$nowin} {
    wm withdraw .
    # if -nowin, then speed up game by factor of 5
    set parms(tick)    [expr $parms(tick)/5]
    set parms(do_wait) [expr $parms(do_wait)/5]
    # and don't bother drawing on canvas or updating robot damage
    proc show_scan {args} {}
    proc show_robots {args} {}
    proc show_explode {args} {}
    proc up_damage {args} {}
  }
  main_win
  update
  foreach f $arg_files {
    .f2.fr.l1 insert end $f
  }
  set numList [llength $arg_files]
  set tlimit $arg_tlimit
  set outfile $arg_outfile
  switch $tourn_type {
    1 {
      tournament
      if {$nowin} {wm withdraw .tourn}
      update
      do_tourn
    }
    4 {
      start
    }
    default {
    }
  }
  clean_up
  update
  destroy .
} else {
  # no files for tourny, run interactive
  set nowin      0
  set tourn_type 0
  main_win
}

# finis


}