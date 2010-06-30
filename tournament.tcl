#****F* tournament/file_header
#
# NAME
#
#   tournament.tcl
#
# DESCRIPTION
#
#   This file defines the functionality and GUI description of the
#   TclRobots tournament mode.
#
#   It runs round-robin one-on-one battles until all robots have battled
#   every other robot once. Scores are awarded for a win (3p) and a tie
#   (1p). At the end of the tournament the scores are compared to find a
#   winner.
#
#   The GUI is the same as single battle mode, with the tournament score
#   added.
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

#****P* tournament/init_tourn
#
# NAME
#
#   init_tourn
#
# DESCRIPTION
#
#   This procedure starts the tournament.
#
# SOURCE
#
proc init_tourn {} {
    global allRobots allRobots_tourn activeRobots activeRobots_tourn data \
        data_tourn score

    # Clear any old data
    array unset data

    if {$::gui} {
        get_filenames_tourn
        init_gui_tourn
    }
    # Init all robots, can't use init_game from tclrobots.tcl because
    # interpreters should be initialised separately in tournament mode
    init_game base
    init_robots

    if {$::gui} {
        # Init robots on GUI
        gui_init_robots

        # Remove canvas items; these will be initialised again for each match
        $::arena_c delete robot
        $::arena_c delete scan
    }
    foreach robot $allRobots {
        set score($robot) 0
    }
    # Remember allRobots, activeRobots and data
    set allRobots_tourn    $allRobots
    set activeRobots_tourn $activeRobots
    array set data_tourn   [array get data]

    build_matchlist

    if {$::debug} {
        #set ::matchlist {{r0 r1} {r0 r1} {r0 r1}}
    }

    if {$::gui} {
        set ::running 0
        set ::stopped 0
        set ::halted  0
        set ::paused  0

        set ::matchnum 0
        set ::tournRanking $allRobots_tourn
        set ::tournScore {}
        foreach robot $allRobots_tourn {
            lappend ::tournScore \
                "[format %3d $score($robot)] $data($robot,name)"
        }
        update_tourn
    }
    # Figure out the longest robot name to line up the report nicely
    set ::long_name 0
    foreach name [array names data *,name] {
        if {[string length $data($name)] > $::long_name} {
            set ::long_name [string length $data($name)]
        }
    }
}
#******

#****P* init_tourn/get_filenames_tourn
#
# NAME
#
#   get_filenames_tourn
#
# DESCRIPTION
#
#   Gets the robot filenames from the file list window.
#
# SOURCE
#
proc get_filenames_tourn {} {
    # get robot filenames from window
    set ::robotFiles $::robotList
}
#******

#****P* init_tourn/init_gui_tourn
#
# NAME
#
#   init_gui_tourn
#
# DESCRIPTION
#
#   Creates theemacs -r ~/Desktop/code/tcl/tclrobots/tclrobots/tclrobots.tcl tournament mode GUI.
#
# SOURCE
#
proc init_gui_tourn {} {
    grid forget $::sel_f

    show_arena

    # Create and grid the tournament control box
    create_tournctrl

    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}

    # start robots
    set ::StatusBarMsg "Optionally select match time and outfile and press START"
    button_state "game" run_tourn reset_tourn
}
#******

#****P* init_gui_tourn/create_tournctrl
#
# NAME
#
#   create_tournctrl
#
# DESCRIPTION
#
#   Create and grid the tournament control box.
#
# SOURCE
#
proc create_tournctrl {} {
    global tourn_f

    # The single battle mode shows the arena, the health box and the
    # message box
    grid $::game_f  -column 0 -row 2 -sticky nsew
    grid $::arena_c -column 0 -row 0 -rowspan 2 -sticky nsew

    set  tourn_f [ttk::frame $::game_f.tourn]
    grid $tourn_f -column 1 -row 0 -sticky nsew

    create_health_msg $tourn_f

    set tournctrl1_f [ttk::frame $tourn_f.time -relief raised -borderwidth 2]
    set tourntime_l  [ttk::label $tourn_f.time.l \
                          -text "Max minutes / match:"]
    set tourntime_e  [ttk::entry $tourn_f.time.e \
                          -textvariable tlimit]

    grid $tourntime_l -column 0 -row 0 -sticky nsew
    grid $tourntime_e -column 0 -row 1 -sticky nsew

    set ::tournScore    {}
    set ::tournScore_lb   [listbox $tourn_f.score -background black \
                               -listvariable ::tournScore]

    set ::tournMatches  {}
    set ::tournMatches_lb [listbox $tourn_f.match -background black \
                               -foreground white -listvariable ::tournMatches]

    set tournctrl2_f [ttk::frame $tourn_f.file -relief raised -borderwidth 2]
    set tournfile_l  [ttk::label $tourn_f.file.l \
                          -text "Optional results filename:"]
    set tournfile_e  [ttk::entry $tourn_f.file.e \
                          -textvariable outfile]

    grid $tournfile_l -column 0 -row 0 -sticky nsew
    grid $tournfile_e -column 0 -row 1 -sticky nsew

    # Fix resizing of widgets
    grid columnconfigure $::game_f 0 -weight 1
    grid columnconfigure $::game_f 1 -weight 1
    grid rowconfigure    $::game_f 0 -weight 1
    grid columnconfigure $tourn_f 0 -weight 1
    grid columnconfigure $tourn_f 1 -weight 1
    grid rowconfigure    $tourn_f  0 -weight 1
    grid rowconfigure    $tourn_f  1 -weight 1
    grid rowconfigure    $tourn_f  2 -weight 1

    # Grid all major widgets
    grid $::robotHealth_lb  -column 0 -row 0 -sticky nsew
    grid $::tournScore_lb   -column 0 -row 1 -sticky nsew
    grid $::tournMatches_lb -column 0 -row 2 -sticky nsew
    grid $tournctrl1_f      -column 0 -row 3 -sticky nsew
    grid $::robotMsg_lb     -column 1 -row 0 -sticky nsew -rowspan 3
    grid $tournctrl2_f      -column 1 -row 3 -sticky nsew
}
#******

#****P* init_tourn/build_matchlist
#
# NAME
#
#   build_matchlist
#
# DESCRIPTION
#
#   Builds the list of matches in the tournament. Makes sure robots do
#   not fight themselves or multiple times against the same opponent.
#
# SOURCE
#
proc build_matchlist {} {
    global allRobots matchlist

    set matchlist {}
    foreach robot $allRobots {
        foreach target $allRobots {
            # Make sure all matches are unique
            if {[<= [lsearch $allRobots $target] \
                     [lsearch $allRobots $robot]]} {
                continue
            }
            lappend matchlist [list $robot $target]
        }
    }
}
#******

#****P* tournament/update_tourn
#
# NAME
#
#   update_tourn
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc update_tourn {} {
    show_score
    show_matches
    update
}
#******

#****P* update_tourn/show_score
#
# NAME
#
#   show_score
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc show_score {} {
    global tournRanking data tournScore_lb

    set index 0
    foreach robot $tournRanking {
        $tournScore_lb itemconfigure $index -foreground $data($robot,color)
        if {$data($robot,brightness) > 0.5} {
            $tournScore_lb itemconfigure $index -background black
        }
        incr index
    }
}
#******

#****P* update_tourn/show_matches
#
# NAME
#
#   show_matches
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc show_matches {} {
    set ::tournMatches {}
    set index 0

    foreach match $::matchlist {
        lappend ::tournMatches "$::data([lindex $match 0],name) vs $::data([lindex $match 1],name)"

        if {$::matchnum == $index} {
            # Highlight current match
            $::tournMatches_lb itemconfigure $index -background white
            $::tournMatches_lb itemconfigure $index -foreground black

            if {$index > 0} {
                # Remove highlight from previous match
                $::tournMatches_lb itemconfigure [- $index 1] \
                    -background black
                $::tournMatches_lb itemconfigure [- $index 1] \
                    -foreground white
            }
        }
        incr index
    }
}
#******

#****P* init_tourn/run_tourn
#
# NAME
#
#   run_tourn
#
# DESCRIPTION
#
#   Runs the tournament.
#
# SOURCE
#
proc run_tourn {} {
    global allRobots allRobots_tourn activeRobots activeRobots_tourn \
        data data_tourn running matchlist score matchlog

    if {$::gui} {
        set ::halted 0
        button_state "running"
    }
    set matchlog ""
    puts "MATCHES:\n"

    foreach match $matchlist {
        if {$::gui} {
            # Remove old canvas items
            $::arena_c delete robot
            $::arena_c delete scan
            debug "Running match $::matchnum $match from $matchlist"
        }
        set robot  [lindex $match 0]
        set target [lindex $match 1]

        # Switch all and active robots to current tournament pair
        set allRobots    "$robot $target"
        set activeRobots $allRobots

        # Unset old data array, but retain some information
        array unset data
        foreach robot $allRobots_tourn {
            set data($robot,code)       $data_tourn($robot,code)
            set data($robot,name)       $data_tourn($robot,name)
            set data($robot,num)        $data_tourn($robot,num)
            set data($robot,color)      $data_tourn($robot,color)
            set data($robot,brightness) $data_tourn($robot,brightness)
        }
        # Init current two robots' interpreters
        init_game match

        if {$::gui} {
            foreach robot $allRobots {
                gui_create_robot $robot $data_tourn($robot,color) \
                    [lsearch -exact $allRobots_tourn $robot]
            }
        }
        set running 1
        set ::stopped 0
        set ::halted 0
        coroutine run_robotsCo run_robots
        vwait ::stopped

        if {$::halted} {
            # Do not score tournament if it was halted
            break
        } else {
            # Set match score for tournament mode
            set match_msg ""
            # Fix padding
            for {set i [string length $data($robot,name)]} \
                {$i <= $::long_name} {incr i} {
                    append match_msg " "
                }
            if {[llength $activeRobots] == 1} {
                incr score([lindex $activeRobots 0]) 3
                if {$robot eq $activeRobots} {
                    append match_msg \
                        "$data($robot,name)(w) vs $data($target,name)"
                } else {
                    append match_msg \
                        "$data($robot,name)    vs $data($target,name)(w)"
                }
            } else {
                # Note that this presupposes two-robot matches
                foreach robot $allRobots {
                    incr score($robot) 1
                }
                append match_msg \
                    "$data($robot,name)    vs $data($target,name) (tie)"
            }
            sort_score

            if {$::gui} {
                update_tourn
                incr ::matchnum
            }
            puts $match_msg
            append matchlog "$match_msg\n"

            # Disable robots and clear messages
            foreach robot $activeRobots {
                disable_robot $robot
                set ::robotMsg {}
            }
        }
    }
    button_state "reset"
    report_score
}
#******

#****P* halt_tourn/reset_tourn
#
# NAME
#
#   reset_tourn
#
# DESCRIPTION
#
#   Reset to file select state.
#
# SOURCE
#
proc reset_tourn {} {
    set ::StatusBarMsg "Cleaning up"
    update

    set ::running 0
    set ::halted 1
    destroy $::tourn_f

    foreach robot $::activeRobots {
        disable_robot $robot
    }
    if {$::parms(tkp)} {
        $::arena_c delete {*}[$::arena_c children 0]
    } else {
        $::arena_c delete all
    }
    grid forget $::game_f
    grid $::sel_f -column 0 -row 2 -sticky nsew

    button_state "file"
    debug button_state
}
#******

#****P* run_tourn/sort_score
#
# NAME
#
#   sort_score
#
# DESCRIPTION
#
#   Sorts tournament scores.
#
# SOURCE
#
proc sort_score {} {
    global allRobots_tourn score tournRanking tournScore data

    set scores {}
    foreach robot $allRobots_tourn {
        lappend scores "$robot $score($robot)"
    }

    set tournRanking {}
    set tournScore   {}
    foreach robotscore [lsort -integer -index 1 \
                            -decreasing $scores] {
        set robot [lindex $robotscore 0]
        lappend tournRanking $robot
        lappend tournScore "[format %3d $score($robot)] $data($robot,name)"
    }
}
#******

#****P* run_tourn/report_score
#
# NAME
#
#   report_score
#
# DESCRIPTION
#
#   Displays scores and if requested reports them to file.
#
# SOURCE
#
proc report_score {} {
    global tournScore matchlog outfile

    set ::win_msg "TOURNAMENT SCORES:\n\n"
    foreach robotscore $tournScore {
        append ::win_msg "$robotscore\n"
    }
    # show results
    if {$::gui} {
        if {$::halted} {
            set ::StatusBarMsg "Battle halted"
        } else {
            tk_dialog2 .winner "Results" $::win_msg "-image iconfn" 0 dismiss
        }
    } else {
        puts "\n$::win_msg"
    }
    # Set up report file message
    set outmsg ""
    append outmsg "MATCHES:\n$matchlog\n"
    append outmsg "$::win_msg"

    if {$outfile ne ""} {
        debug "$outfile :::: $outmsg"
        catch {write_file $outfile $outmsg}
    }
}
#******
