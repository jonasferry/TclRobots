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
#   Starts a single battle.
#
# SOURCE
#
proc init_battle {} {
    # get robot filenames from window
    set ::robotFiles $::robotList

    grid forget $::sel_f

    # The single battle mode shows the arena, the health box and the
    # message box
    grid $::game_f -column 0 -row 2 -sticky nsew
    grid $::arena_c        -column 0 -row 0 -rowspan 2 -sticky nsew
    grid $::robotHealth_lb -column 1 -row 0            -sticky nsew
    grid $::robotMsg_lb    -column 1 -row 1            -sticky nsew
    grid columnconfigure $::game_f 0 -weight 1
    grid rowconfigure    $::game_f 0 -weight 1
    grid columnconfigure $::game_f 1 -weight 1

    show_arena

    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}

    # start robots
    set ::StatusBarMsg "Running"
    set ::halted  0
    button_state disabled "Halt" halt

    # Init robots
    init

    # Init robots on GUI
    gui_init_robots

    # Start game
    run_game

    # find winnner
    if {$::halted} {
        set ::StatusBarMsg "Battle halted"
    } else {
        tk_dialog2 .winner "Results" $::win_msg "-image iconfn" 0 dismiss
    }
    button_state disabled "Reset" reset
}
#******

#****P* init_battle/halt
#
# NAME
#
#   halt
#
# DESCRIPTION
#
#   halt a running match
#
# SOURCE
#
proc halt {} {
    set ::running 0
    set ::StatusBarMsg "Stopping battle, standby"
    set ::halted 1

    button_state disabled "Reset" reset
}
#******

#****P* init_battle/reset
#
# NAME
#
#   reset
#
# DESCRIPTION
#
#   reset to file select state
#
# SOURCE
#
proc reset {} {
    clean_up

    if {$::data(tkp)} {
        $::arena_c delete {*}[$::arena_c children 0]
    } else {
        $::arena_c delete all
    }
    grid forget $::game_f
    destroy $::game_f.sim
    grid $::sel_f -column 0 -row 2 -sticky nsew

    set ::StatusBarMsg "Select robot files for battle"
    button_state normal "Run Battle" {init_mode battle}
}
#******

#****P* reset/clean_up
#
# NAME
#
#   clean_up
#
# DESCRIPTION
#
#   clean up all left overs
#
# SOURCE
#
proc clean_up {} {
    set ::StatusBarMsg "Standby, cleaning up any left overs...."
    update

    foreach robot $::activeRobots {
        disable_robot $robot
    }
}
#******
