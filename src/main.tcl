#****F* main/file_header
#
# NAME
#
#   tclrobots.tcl
#
# DESCRIPTION
#
#   This is the main file of TclRobots. It sources gui.tcl if GUI is
#   requested, but can be used stand-alone.
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

#******
# CODING STANDARD
#
# In no particular order:
#
#  * Minimize the number of global variables. The default global
#    variables are argv, data, game and parms.
#
#  * The global keyword is preferred over the :: notation. List global
#    variables in alphabetical order. See proc main for an example.
#
#
#******

#****P* main/startup
#
# NAME
#
#   startup
#
# DESCRIPTION
#
#   The startup proc is run at program startup.
#
# SOURCE
#
proc startup {} {
    global allRobots argv data game gui nomsg os tcl_platform \
	thisDir thisScript

    set thisScript [file join [pwd] [info script]]
    set thisDir [file dirname $thisScript]

    namespace import ::tcl::mathop::*
    namespace import ::tcl::mathfunc::*

    # Check current operating system
    if {$tcl_platform(platform) eq "windows"} {
	set os "windows"
    } elseif {$tcl_platform(os) eq "Darwin"} {
	set os "mac"
    } else {
	set os "linux"
    }
    set gui              0
    set nomsg            0
    set game(debug)      0
    set game(max_ticks)  6000
    set game(robotfiles) {}
    set game(tourn_type) 0
    set game(outfile)    ""
    set game(loglevel)   1
    set game(simulator)  0
    set game(state)      ""
    set game(numbattle)  1
    set game(winner)     {}

    set len [llength $argv]
    for {set i 0} {$i < $len} {incr i} {
        set arg [lindex $argv $i]

        switch -regexp -- $arg  {
            --debug   {set game(debug) 1}
            --gui     {set gui 1}
	    --help    {create_display; show_usage; return}
            --nomsg   {set nomsg 1}
            --n       {incr i; set game(numbattle) [lindex $argv $i]}
            --o       {incr i; set game(outfile) $arg}
            --seed    {incr i; set game(seed_arg) [lindex $argv $i]}
            --t.*     {set game(tourn_type) 1}
            --version {create_display; display "TclRobots $version"; return}
            default {
                if {[file isfile [pwd]/$arg]} {
                    lappend game(robotfiles) [pwd]/$arg
                } else {
                    display "'$arg' not found, skipping"
                }
            }
        }
    }
    source [file join $thisDir init.tcl]
    source [file join $thisDir game.tcl]

    if {[llength $game(robotfiles)] >= 2 && !$gui} {
	create_display
        if {$game(tourn_type) == 0} {
            # Run single battle in terminal
	    if {$game(numbattle) == 1} {
		display "\nSingle battle started\n"
	    } else {
		display "\nSingle battles started\n"
	    }
            set running_time [/ [lindex [time {
		while {$game(numbattle) > 0} {
		    init_game
		    init_match 
		    run_game
		    set game(state) ""
		    incr game(numbattle) -1
		}
	    }] 0] 1000000.0]
            display "seed: $game(seed)"
            display "time: $running_time seconds"
	    if {$game(numbattle) == 1} {
		display "\nSingle battle finished\n"
	    } else {
		display "\nSingle battles finished\n"
		foreach robot $allRobots {
		    set count 0
		    foreach winner $game(winner) {
			if {$data($robot,name) eq $winner} {
			    incr count
			}
		    }
		    lappend winnerList "$count $data($robot,name)"
		}
		foreach item [lsort -index 0 -decreasing $winnerList] {
		    display $item
		}
		# Newline for pretty output
		display ""
	    }
        } else {
            # Run tournament in terminal
            display "\nTournament started\n"
            source [file join $thisDir tournament.tcl]
            set running_time [/ [lindex [time {init_tourn;run_tourn}] 0] \
                                  1000000.0]
            display "seed: $game(seed)"
            display "time: $running_time seconds\n"
            display "Tournament finished\n"
        }
    } else {
        # Run GUI
        set gui 1
        source [file join $thisDir gui.tcl]
        init_gui
    }
}
#******

#****P* main/create_display
#
# NAME
#
#   create_display
#
# DESCRIPTION
#
#   Windows has no standard output, so a special text box is created
#   to display game text messages.
#
# SOURCE
#
proc create_display {} {
    global display_t gui os

    if {[eq $os "windows"] && !$gui} {
	package require Tk

	grid columnconfigure . 0 -weight 1 
	grid rowconfigure    . 0 -weight 1

	# Create display text area
	set display_t [tk::text .t -width 80 -height 30 -wrap word \
			   -yscrollcommand ".s set"]

	# Create scrollbar for display window
	set display_s [ttk::scrollbar .s -command ".t yview" \
			   -orient vertical]
	# Grid the text box and scrollbar
	grid $display_t -column 0 -row 1 -sticky nsew
	grid $display_s -column 1 -row 1 -sticky ns
    }
}
#******

#****P* main/show_usage
#
# NAME
#
#   show_usage
#
# DESCRIPTION
#
#   Shows command-line arguments.
#
# SOURCE
#
proc show_usage {} {
    global version

    display "
TclRobots $version

Command-line arguments (in any order):

--debug     : Enable debug messages and lowered health for quicker battles.
--gui       : Use GUI; useful in combination with robot files.
--help      : Show this help.
--msg       : Disable robot messages.
--n <N>     : Run N number of battles.
--o <FILE>  : Set results output file.
--seed <S>  : Start with random seed S to replay a specific battle.
--t*        : Run tournament in batch mode.
--version   : Show version and exit.
<robot.tr> : Add one ore more robot files.
"
}
#******

#****P* main/run_game
#
# NAME
#
#   run_game
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc run_game {} {
    global activeRobots game

    set game(state) "run"
    coroutine run_robotsCo run_robots
    while {$game(state) eq "run" ||
	   $game(state) eq "pause"} {
	vwait game(state)
    }
    if {$game(state) ne "halt"} {
	find_winner
    }
}
#******

#****P* run_game/find_winner
#
# NAME
#
#   find_winner
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc find_winner {} {
    global activeRobots allRobots data finish game robmsg_out win_msg winner 

    set winner ""
    set num_team 0
    set diffteam ""
    set win_color black
    foreach robot $activeRobots {
        lappend winner $data($robot,name)
	lappend game(winner) $data($robot,name)

        if {$data($robot,team) != ""} {
            if {[lsearch -exact $diffteam $data($robot,team)] == -1} {
                lappend diffteam $data($robot,team)
                incr num_team
            }
        } else {
            incr num_team
        }
    }
    # Set winner announcement
    switch [llength $activeRobots] {
        0 {
            set win_msg "No robots left alive"
        }
        1 {
            if {[string length $diffteam] > 0} {
                set diffteam "Team $diffteam"
                set win_msg "WINNER:\n$diffteam\n$winner\n"
            } else {
                set win_msg "WINNER:\n$winner"
            }
        }
        default {
            # check for teams
            if {$num_team == 1} {
                set win_msg "WINNER:\nTeam $diffteam\n$winner"
            } else {
                set win_msg "TIE:\n$winner"
            }
        }
    }
    display "$win_msg\n"
    foreach robot $activeRobots {
        disable_robot $robot
    }
    set score "score: "
    set points 1
    foreach l [split $finish \n] {
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
    set players "BATTLE:\n"
    foreach robot $allRobots {
        append players "$data($robot,name) "
    }
    # Set up report file message
    set outmsg ""
    append outmsg "$players\n\n"
    append outmsg "$win_msg\n\n"
    if {$finish ne ""} {
        append outmsg "DEFEATED:\n$finish\n"
    }
    append outmsg "SCORE:\n$score\n\n"
    append outmsg "MESSAGES:\n$robmsg_out"

    if {$game(outfile) ne ""} {
        catch {write_file $game(outfile) $outmsg}
    }
}
#******

#****P* main/write_file
#
# NAME
#
#   write_file
#
# DESCRIPTION
#
#   Writes a string to a file
#
# SOURCE
#
proc write_file {file str} {
    set fd [open $file w]
    display $fd $str
    close $fd
}
#******

#****P* main/syscall
#
# NAME
#
#   syscall
#
# DESCRIPTION
#
#   Handle syscalls from robots
#
# SOURCE
#
proc syscall {args} {
    global data tick

    set robot [lindex $args 0]
    set result 0

    set syscall [lrange $args 1 end]

    # Handle all immediate syscalls
    switch [lindex $syscall 0] {
        dputs {
            sysDputs $robot [lrange $args 2 end]
        }
        rand {
            set result [mrand [lindex $syscall 1]]
        }
        team_send {
            sysTeamSend $robot [lindex $syscall 1]
        }
        team_get {
            set result [sysTeamGet $robot]
        }
        callback {
            set ticks  [lindex $syscall 1]
            set script [lindex $syscall 2]
            set when [+ $tick $ticks]
            lappend data($robot,callbacks) [list $when $script]
            set data($robot,callbacks) \
                    [lsort -integer -index 0 $data($robot,callbacks)]
        }
        callbackcheck {
            set when [lindex $data($robot,callbacks) 0 0]
            if {$when ne "" && $when <= $tick} {
                set result [lindex $data($robot,callbacks) 0 1]
                set data($robot,callbacks) \
                        [lrange $data($robot,callbacks) 1 end]
            } else {
                set result ""
            }
        }
        default {
            # All postponed syscalls ends up here
            set data($robot,syscall,$tick) $syscall
        }
    }
    return $result
}
#******

#****P* syscall/sysScanner
#
# NAME
#
#   sysScanner
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysScanner {robot} {
    global activeRobots data parms tick 

    if {($data($robot,syscall,$tick) eq \
             $data($robot,syscall,[- $tick 1]))} {

        set deg [lindex $data($robot,syscall,$tick) 1]
        set res [lindex $data($robot,syscall,$tick) 2]

        set dsp    0
        set health 0
        set near   9999
        foreach target $activeRobots {
            if {"$target" == "$robot"} {
                continue
            }
            set x [- $data($target,x) $data($robot,x)]
            set y [- $data($target,y) $data($robot,y)]
            set d [round [* 57.2958 [atan2 $y $x]]]

            if {$d < 0} {
                incr d 360
            }
            set d1  [% [+ [- $d $deg] 360] 360]
            set d2  [% [+ [- $deg $d] 360] 360]

            if {$d1 < $d2} {
                set f $d1
            } else {
                set f $d2
            }
            if {$f<=$res} {
                set data($target,ping) $data($robot,num)
                set dist [round [hypot $x $y]]

                if {$dist<$near} {
                    set derr [* $parms(errdist) $res]

                    if {$res > 0} {
                        set terr [+ 5 [mrand $derr]]
                    } else {
                        set terr [+ 0 [mrand $derr]]
                    }
                    if {[mrand 2]} {
                        set fud1 -
                    } else {
                        set fud1 +
                    }
                    if {[mrand 2]} {
                        set fud2 -
                    } else {
                        set fud2 +
                    }
                    set near [$fud1 $dist [$fud2 $terr $data($robot,btemp)]]

                    if {$near < 1} {
                        set near 1
                    }
                    set dsp    $data($robot,num)
                    set health $data($robot,health)
                }
            }
        }
        # if cannon has overheated scanner, report 0
        if {$data($robot,btemp) >= $parms(scanbad)} {
            set data($robot,sig) "0 0"
            set val 0
        } else {
            set data($robot,sig) "$dsp $health"

            if {$near == 9999} {
                set val 0
            } else {
                set val $near
            }
        }
        set data($robot,sysreturn,$tick) $val

    } else {
        set data($robot,sysreturn,$tick) 0
    }
}
#******

#****P* syscall/sysDsp
#
# NAME
#
#   sysDsp
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysDsp {robot} {
    global data tick

    set data($robot,sysreturn,$tick) $data($robot,sig)
}
#******

#****P* syscall/sysAlert
#
# NAME
#
#   sysAlert
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysAlert {robot} {
    global data tick

    set data($robot,alert) [lindex $data($robot,syscall,$tick) 1]
    set data($robot,sysreturn,$tick) 1
}
#******

#****P* syscall/sysCannon
#
# NAME
#
#   sysCannon
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysCannon {robot} {
    global data parms tick

    set deg [lindex $data($robot,syscall,$tick) 1]
    set rng [lindex $data($robot,syscall,$tick) 2]

    set val 0

    if {$data($robot,mstate)} {
        set val 0
    } elseif {$data($robot,reload)} {
        set val 0
    } elseif {[catch {set deg [round $deg]}]} {
        set val -1
    } elseif {[catch {set rng [round $rng]}]} {
        set val -1
    } elseif {($deg < 0) || ($deg > 359)} {
        set val -1
    } elseif {($rng < 0) || ($rng > $parms(mismax))} {
        set val -1
    } else {
        set data($robot,mhdg)   $deg
        set data($robot,mdist)  $rng
        set data($robot,mrange) 0
        set data($robot,mstate) 1
        set data($robot,morgx)  $data($robot,x)
        set data($robot,morgy)  $data($robot,y)
        set data($robot,mx)     $data($robot,x)
        set data($robot,my)     $data($robot,y)
        incr data($robot,btemp) $parms(canheat)
        incr data($robot,mused)
        # set longer reload time if used all missiles in clip
        if {$data($robot,mused) == $parms(clip)} {
            set data($robot,reload) $parms(lreload)
            set data($robot,mused) 0
        } else {
            set data($robot,reload) $parms(mreload)
        }
        set val 1
    }
    set data($robot,sysreturn,$tick) $val
}
#******

#****P* syscall/sysDrive
#
# NAME
#
#   sysDrive
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysDrive {robot} {
    global data parms tick

    set deg [lindex $data($robot,syscall,$tick) 1]
    set spd [lindex $data($robot,syscall,$tick) 2]

    set d1  [% [+ [- $data($robot,hdg) $deg] 360] 360]
    set d2  [% [+ [- $deg $data($robot,hdg)] 360] 360]

    if {$d1 < $d2} {
        set d $d1
    } else {
        set d $d2
    }
    set data($robot,dhdg) $deg

    if {$data($robot,hflag) && ($spd > $parms(heatsp))} {
        set data($robot,dspeed) $parms(heatsp)
    } else {
        set data($robot,dspeed) $spd
    }
    # shutdown drive if turning too fast at current speed
    set index [int [/ $d 25]]
    if {$index > 3} {
        set index 3
    }
    if {$data($robot,speed) > $parms(turn,$index)} {
        set data($robot,dspeed) 0
        set data($robot,dhdg)   $data($robot,hdg)
    } else {
        set data($robot,orgx)  $data($robot,x)
        set data($robot,orgy)  $data($robot,y)
        set data($robot,range) 0
    }
    # find direction of turn
    if {($data($robot,hdg)+$d+360)%360==$deg} {
        set data($robot,dir) +
    } else {
        set data($robot,dir) -
    }
    set data($robot,sysreturn,$tick) $data($robot,dspeed)
}
#******

#****P* syscall/sysData
#
# NAME
#
#   sysData
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysData {robot} {
    global data tick

    set val 0

    switch $data($robot,syscall,$tick) {
        health {set val $data($robot,health)}
        speed  {set val $data($robot,speed)}
        heat   {set val $data($robot,heat)}
        loc_x  {set val $data($robot,x)}
        loc_y  {set val $data($robot,y)}
    }
    set data($robot,sysreturn,$tick) $val
}
#******

#****P* syscall/sysTick
#
# NAME
#
#   sysTick
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysTick {robot} {
    global data tick

    set data($robot,sysreturn,$tick) $tick
}
#******

#****P* syscall/sysTeamDeclare
#
# NAME
#
#   sysTeamDeclare
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysTeamDeclare {robot} {
    global data tick

    set team [lindex $data($robot,syscall,$tick) 1]
    set data($robot,team) $team
    set data($robot,sysreturn,$tick) $team
}
#******

#****P* syscall/sysTeamSend
#
# NAME
#
#   sysTeamSend
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysTeamSend {robot msg} {
    global data

    display "sysTeamSend $robot $msg"
    set data($robot,data) $msg
}
#******

#****P* syscall/sysTeamGet
#
# NAME
#
#   sysTeamGet
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysTeamGet {robot} {
    global data activeRobots tick

    set val ""

    if {$data($robot,team) ne {}} {
        foreach target $activeRobots {
            if {"$robot" eq "$target"} {continue}
            if {"$data($robot,team)" eq "$data($target,team)"} {
                lappend val [list $data($target,num) $data($target,data)]
            }
        }
    }
    if {$val ne {}} {
        display "sysTeamGet $robot $val"
    }
    return $val
}
#******

#****P* syscall/sysDputs
#
# NAME
#
#   sysDputs
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc sysDputs {robot msg} {
    global data game gui nomsg robmsg_out tick

    if {!$nomsg} {
	set msg [join $msg]

	if {$gui} {
	    # Output to robot message box
	    show_msg $robot $msg
	} else {
	    # Output to terminal
	    display "$data($robot,name): $msg"
	}
	if {$game(outfile) ne ""} {
	    append robmsg_out "$data($robot,name): $msg\n"
	}
    }
}
#******

#****P* main/mrand
#
# NAME
#
#   mrand
#
# DESCRIPTION
#
#   Return random integer 1-max
#
# SOURCE
#
proc mrand {max} {
    return [int [* [rand] $max]]
}
#******

#****P* main/display
#
# NAME
#
#   display
#
# DESCRIPTION
#
#   Displays text $msg.
#
# SOURCE
#
proc display {msg} {
    global display_t gui os

    if {!$gui && [eq $os "windows"]} {
	$display_t insert end "$msg\n"
	$display_t see end
	update
    } else {
	puts $msg
    }
}
#******

#****P* main/debug
#
# NAME
#
#   debug
#
# DESCRIPTION
#
#   Prints debug message. The proc name makes it easy to search for.
#   Precede other debug changes with the word debug in a comment. Note
#   that TclRobots has to be called with the -debug flag for debug
#   messages to display.
#
#   If the first argument to debug is "breakpoint" execution will halt
#   until ::broken is set to 0 e.g. by Tkinspect.
#
#   If the first argument is "exit", debug will print the message and
#   exit TclRobots.
#
#   The name of the procedure that called debug is automatically
#   included in the debug message.
#
# SOURCE
#
proc debug {args} {
    global broken game
   
    if {$game(debug)} {
        # Display name of procedure that called debug
        set caller [lindex [info level [- [info level] 1]] 0]
        if {[lindex $args 0] eq "breakpoint"} {
            set broken 1
            display "Breakpoint reached (dbg: $caller)"
            vwait broken
        } elseif {[lindex $args 0] eq "exit"} {
            # Calling with 'debug exit "msg"' prints the message and then
            # exits. This is useful for "checkpoint" style debugging.
            display "- [join [lrange $args 1 end]] (dbg: $caller)\n"
            exit
        } else {
            display "- [join $args] (dbg: $caller)\n"
        }
    }
}
#******

# All procs are sourced; enter main proc; see top of file.
startup
