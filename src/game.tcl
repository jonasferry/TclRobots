#****F* game/file_header
#
# NAME
#
#   game.tcl
#
# DESCRIPTION
#
#   This file contains the game logic.
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

#****P* game/run_robots
#
# NAME
#
#   run_robots
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc run_robots {} {
    global activeRobots data do_step game gui parms sim_syscall StatusBarMsg \
    step tick timeAt5

    while {$game(state) eq "run" || $game(state) eq "pause"} {
        if {$game(state) ne "pause"} {
            if {$game(simulator)} {
                # Reset health of target
                set data(target,health) [* $parms(health) 10]
            }
            foreach robot $activeRobots {
                if {($data($robot,alert) ne {}) && \
                        ($data($robot,ping) ne {})} {
                    # Prepend alert data to sysreturn no notify robot it's
                    # been scanned.
                    set data($robot,sysreturn,[- $tick 1]) \
                        "alert $data($robot,alert) $data($robot,ping) $data($robot,sysreturn,[- $tick 1])"

                    # Robot is notified; reset alert request
                    set data($robot,ping) {}
                }
                ${robot}Run $data($robot,sysreturn,[- $tick 1])
            }
            act

            # Print extra information in simulator GUI
            if {$game(simulator) && $data(r0,sysreturn,$tick) ne ""} {
                set sim_syscall $data(r0,syscall,$tick)
                append sim_syscall " => " $data(r0,sysreturn,$tick)
            }
            update_robots

            if {$gui} {
                update_gui
            }
            tick

            # Check if single step is active in simulator mode
            if {$game(simulator) && $step} {
                vwait do_step
                set do_step 0
            }
            if {$parms(tick) < 5} {
                # Don't bother at high speed
                after $parms(tick) [info coroutine]
            } elseif {$tick <= 5} {
                # Let the first few ticks pass before measuring
                after $parms(tick) [info coroutine]
                set timeAt5 [clock milliseconds]
            } else {
                # Try to measure time, to adjust the tick delay for load
                set target [expr {$parms(tick) * ($tick - 4) + $timeAt5}]
                set delay [expr {$target - [clock milliseconds]}]
                # Sanity check value
                if {$delay > $parms(tick)} {
                    set delay $parms(tick)
                } elseif {$delay < 5} {
                    set delay 5
                }
                after $delay [info coroutine]
                # Keep the lag visible
                set StatusBarMsg "Running $delay"
            }
            yield
        } else {
            # Game is paused, but GUI needs to respond
            update
            # Keep timebase up to date to not get skewed during pause
            set timeAt5 [expr {[clock milliseconds] - $parms(tick) * ($tick - 4)}]
        }
    }
    rename [info coroutine] ""
    yield
}
#******

#****P* run_robots/act
#
# NAME
#
#   act
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc act {} {
    global activeRobots data tick

    foreach robot $activeRobots {
        if {$data($robot,status)} {
            set currentSyscall $data($robot,syscall,$tick)
            switch [lindex $currentSyscall 0] {
                scanner      {sysScanner     $robot}
                dsp          {sysDsp         $robot}
                alert        {sysAlert       $robot}
                cannon       {sysCannon      $robot}
                drive        {sysDrive       $robot}
                health       -
                speed        -
                heat         -
                loc_x        -
                loc_y        {sysData        $robot}
                tick         {sysTick        $robot}
                team_declare {sysTeamDeclare $robot}
            }
        }
    }
}
#******

#****P* run_robots/update_robots
#
# NAME
#
#   update_robots
#
# DESCRIPTION
#
#   update position of missiles and robots, assess damage
#
# SOURCE
#
proc update_robots {} {
    global allRobots data game

    foreach robot $allRobots {
        # check all flying missiles
        set num_miss [check_missiles $robot]

        # skip rest if robot dead
        if {!$data($robot,status)} {
            continue
        }
        # update missile reloader
        if {$data($robot,reload)} {
            incr data($robot,reload) -1
        }
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
        set game(state) "end"
    }
}
#******

#****P* update_robots/check_missiles
#
# NAME
#
#   check_missiles
#
# DESCRIPTION
#
#   check all flying missiles
#
# SOURCE
#
proc check_missiles {robot} {
    global activeRobots data 
    set num_miss 0

    if {$data($robot,mstate)} {
        incr num_miss
        update_missile_location $robot
        # check if missile reached target
        if {$data($robot,mrange) > $data($robot,mdist)} {
            missile_reached_target $robot

            # assign damage to all within explosion ranges
            foreach target $activeRobots {
                if {!$data($target,status)} {
                    continue
                }
                assign_missile_damage $robot $target
            }
        }
    }
    return $num_miss
}
#******

#****P* update_robots/update_missile_location
#
# NAME
#
#   update_missile_location
#
# DESCRIPTION
#
#   update location of missile
#
# SOURCE
#
proc update_missile_location {robot} {
    global c_tab data parms s_tab

    set data($robot,mrange) \
        [+ $data($robot,mrange) $parms(msp)]
    set data($robot,mx) \
        [+ [* $c_tab($data($robot,mhdg)) $data($robot,mrange)] \
             $data($robot,morgx)]
    set data($robot,my) \
        [+ [* $s_tab($data($robot,mhdg)) $data($robot,mrange)] \
             $data($robot,morgy)]
}
#******

#****P* update_robots/missile_reached_target
#
# NAME
#
#   missile_reached_target
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc missile_reached_target {robot} {
    global c_tab data gui s_tab

    set data($robot,mstate) 0
    set data($robot,mx) \
        [+ [* $c_tab($data($robot,mhdg)) $data($robot,mdist)] \
             $data($robot,morgx)]
    set data($robot,my) \
        [+ [* $s_tab($data($robot,mhdg)) $data($robot,mdist)] \
             $data($robot,morgy)]
    if {$gui} {
        after 1 "show_explode $robot"
    }
}
#******

#****P* update_robots/assign_missile_damage
#
# NAME
#
#   assign_missile_damage
#
# DESCRIPTION
#
#   assign damage to all within explosion ranges
#
# SOURCE
#
proc assign_missile_damage {robot target} {
    global data parms

    set d [hypot [- $data($robot,mx) $data($target,x)] \
            [- $data($robot,my) $data($target,y)]]
    if {$d < $parms(dia3)} {
        if {$d < $parms(dia0)} {
            incr data($target,health) $parms(hit0)
            incr data($robot,inflicted) [- $parms(hit0)]
        } elseif {$d<$parms(dia1)} {
            incr data($target,health) $parms(hit1)
            incr data($robot,inflicted) [- $parms(hit1)]
        } elseif {$d<$parms(dia2)} {
            incr data($target,health) $parms(hit2)
            incr data($robot,inflicted) [- $parms(hit2)]
        } else {
            incr data($target,health) $parms(hit3)
            incr data($robot,inflicted) [- $parms(hit3)]
        }
    }
}
#******

#****P* update_robots/check_barrel
#
# NAME
#
#   check_barrel
#
# DESCRIPTION
#
#   check for barrel overheat, apply cooling
#
# SOURCE
#
proc check_barrel {robot} {
    global data parms

    if {$data($robot,btemp)} {
        incr data($robot,btemp) $parms(cancool)
        if {$data($robot,btemp) < 0} {
            set data($robot,btemp) 0
        }
    }
}
#******

#****P* update_robots/check_speed
#
# NAME
#
#   check_speed
#
# DESCRIPTION
#
#   check for excessive speed, increment heat
#
# SOURCE
#
proc check_speed {robot} {
    global data parms

    if {$data($robot,speed) > $parms(heatsp)} {
        incr data($robot,heat) \
            [+ [round [/ [- $data($robot,speed) $parms(heatsp)] \
                           $parms(hrate)]] 1]
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
#******

#****P* update_robots/update_speed
#
# NAME
#
#   update_speed
#
# DESCRIPTION
#
#   update robot speed, moderated by acceleration
#
# SOURCE
#
proc update_speed {robot} {
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
#******

#****P* update_robots/update_heading
#
# NAME
#
#   update_heading
#
# DESCRIPTION
#
#   update robot heading, moderated by turn rates
#
# SOURCE
#
proc update_heading {robot} {
    global data parms

    if {$data($robot,hdg) != $data($robot,dhdg)} {
        set mrate $parms(rate,[int [/ $data($robot,speed) 25]])
        set d1 [% [+ [- $data($robot,dhdg) $data($robot,hdg)]  360] 360]
        set d2 [% [+ [- $data($robot,hdg)  $data($robot,dhdg)] 360] 360]

        if {$d1 < $d2} {
            set d $d1
        } else {
            set d $d2
        }
        if {$d <= $mrate} {
            set data($robot,hdg) $data($robot,dhdg)
        } else {
            set data($robot,hdg) \
                [% [+ [$data($robot,dir) $data($robot,hdg) $mrate] 360] 360]
        }
        set data($robot,orgx)  $data($robot,x)
        set data($robot,orgy)  $data($robot,y)
        set data($robot,range) 0
    }
}
#******

#****P* update_robots/update_distance
#
# NAME
#
#   update_distance
#
# DESCRIPTION
#
#   update distance traveled on this heading
#
# SOURCE
#
proc update_distance {robot} {
    global c_tab data parms s_tab

    if {$data($robot,speed) > 0} {
        set data($robot,range) \
            [+ $data($robot,range) \
                 [/ [* $data($robot,speed) $parms(sp)] 100.0]]

        # Modify range with random factor to avoid totally
        # deterministic movement. Range is currently +- 1%.
        # Playtesting will tell if this should be lower or higher.
        set randfactor [/ [+ [mrand 100] 1.0] 10000]
        if {[mrand 2] == 0} {
            set randfactor [- $randfactor]
        }
        set data($robot,range) [+ $data($robot,range) \
                                    [* $data($robot,range) \
                                         $randfactor]]

        set data($robot,x) \
            [round [+ [* $c_tab($data($robot,hdg)) $data($robot,range)] \
                         $data($robot,orgx)]]

        set data($robot,y) \
            [round [+ [* $s_tab($data($robot,hdg)) $data($robot,range)] \
                        $data($robot,orgy)]]
    }
}
#******

#****P* update_robots/check_wall
#
# NAME
#
#   check_wall
#
# DESCRIPTION
#
#   check for wall collision
#
# SOURCE
#
proc check_wall {robot} {
    global data parms

    if {$data($robot,speed) > 0} {
        if {($data($robot,x) < 0) || ($data($robot,x) > 999)} {
            if {$data($robot,x) < 0} {
                set data($robot,x) 0
            } else {
                set data($robot,x) 999
            }
            set data($robot,orgx)    $data($robot,x)
            set data($robot,orgy)    $data($robot,y)
            set data($robot,range)   0
            set data($robot,speed)   0
            set data($robot,dspeed)  0
            incr data($robot,health) $parms(coll)
        }
        if {($data($robot,y) < 0) || ($data($robot,y) > 999)} {
            if {$data($robot,y) < 0} {
                set data($robot,y) 0
            } else {
                set data($robot,y) 999
            }
            set data($robot,orgx)    $data($robot,x)
            set data($robot,orgy)    $data($robot,y)
            set data($robot,range)   0
            set data($robot,speed)   0
            set data($robot,dspeed)  0
            incr data($robot,health) $parms(coll)
        }
    }
}
#******

#****P* update_robots/check_health
#
# NAME
#
#   check_health
#
# DESCRIPTION
#
#   check for robot health
#
# SOURCE
#
proc check_health {} {
    global activeRobots data finish gui tick

    set num_rob  0
    set diffteam ""
    set num_team 0
    foreach robot $activeRobots {
        if {$data($robot,status)} {
            if {$data($robot,health) <= 0 } {
                set data($robot,status) 0
                set data($robot,health) 0
                disable_robot $robot
                append finish "$data($robot,name) team($data($robot,team)) dead at tick: $tick\n"
                if {$gui} {
                    after 1 "show_die $robot"
                }
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
    return [list $num_rob $diffteam $num_team]
}
#******

#****P* check_health/disable_robot
#
# NAME
#
#   disable_robot
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc disable_robot {robot} {
    global activeRobots data tick

    if {[interp exists $data($robot,interp)]} {
        interp delete $data($robot,interp)
        set index [lsearch -exact $activeRobots $robot]
        set activeRobots [lreplace $activeRobots $index $index]
        array unset data $robot
    } else {
        display "disable robot $robot failed; interp does not exist"
    }
}
#******

#****P* run_robots/tick
#
# NAME
#
#   tick
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc tick {} {
    global game tick

    if {$tick < $game(max_ticks)} {
        incr tick
    } else {
        set game(state) "end"
    }
}
#******
