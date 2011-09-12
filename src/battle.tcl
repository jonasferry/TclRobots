#****F* battle/file_header
#
# NAME
#
#   battle.tcl
#
# DESCRIPTION
#
#   This file contains the GUI description of the TclRobots single
#   battle mode.
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

#****P* battle/init_battle
#
# NAME
#
#   init_battle
#
# DESCRIPTION
#
#   Start a single battle.
#
# SOURCE
#
proc init_battle {} {
    global data game game_f

    # Clear any old data
    array unset data

    # get robot filenames from window
    set game(robotfiles) $::robotList

    grid_battle_gui
    show_arena

    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}

    # Init
    init_game
    init_match

    # start robots
    set ::StatusBarMsg "Press START to start battle"
    button_state "game" run_battle reset_battle
}
#******

#****P* init_battle/grid_battle_gui
#
# NAME
#
#   grid_battle_gui
#
# DESCRIPTION
#
#   Grid the battle GUI.
#
# SOURCE
#
proc grid_battle_gui {} {
    global arena_c game_f robotHealth_lb robotMsg_lb sel_f

    grid forget $sel_f

    # The single battle mode shows the arena, the health box and the
    # message box
    grid $game_f -column 0 -row 2 -sticky nsew
    grid $arena_c        -column 0 -row 0 -rowspan 2 -sticky nsew
    grid $robotHealth_lb -column 1 -row 0            -sticky nsew
    grid $robotMsg_lb    -column 2 -row 0            -sticky nsew
    grid columnconfigure $game_f 0 -weight 1
    grid rowconfigure    $game_f 0 -weight 1
    grid columnconfigure $game_f 1 -weight 1
    grid columnconfigure $game_f 2 -weight 1
}
#******

#****P* init_battle/run_battle
#
# NAME
#
#   run_battle
#
# DESCRIPTION
#
#   Run single battle.
#
# SOURCE
#
proc run_battle {} {
    global game

    button_state "game" "Reset" reset_battle

    # Init robots on GUI
    gui_init_robots

    button_state "running"
    run_game

    puts "state: $game(state)"

    # find winnner
    if {$game(state) eq "halt"} {
        set ::StatusBarMsg "Battle halted"
    } else {
        tk_dialog2 .winner "Results" $::win_msg "-image iconfn" 0 dismiss
    }
}
#******

#****P* halt_battle/reset_battle
#
# NAME
#
#   reset_battle
#
# DESCRIPTION
#
#   Reset to file select state.
#
# SOURCE
#
proc reset_battle {} {
    global game parms

    set game(state) "halt"

    set ::StatusBarMsg "Cleaning up"
    update

    foreach robot $::activeRobots {
        disable_robot $robot
    }
    if {$parms(tkp)} {
        $::arena_c delete {*}[$::arena_c children 0]
    } else {
        $::arena_c delete all
    }
    grid forget $::game_f
    grid $::sel_f -column 0 -row 2 -sticky nsew

    button_state "file"
}
#******
