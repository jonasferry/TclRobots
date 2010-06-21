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
    global data

    # Clear any old data
    array unset data

    # get robot filenames from window
    set ::robotFiles $::robotList

    grid forget $::sel_f

    create_health_msg $::game_f

    # The single battle mode shows the arena, the health box and the
    # message box
    grid $::game_f -column 0 -row 2 -sticky nsew
    grid $::arena_c        -column 0 -row 0 -rowspan 2 -sticky nsew
    grid $::robotHealth_lb -column 1 -row 0            -sticky nsew
    grid $::robotMsg_lb    -column 2 -row 0            -sticky nsew
    grid columnconfigure $::game_f 0 -weight 1
    grid rowconfigure    $::game_f 0 -weight 1
    grid columnconfigure $::game_f 1 -weight 1
    grid columnconfigure $::game_f 2 -weight 1

    show_arena

    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}

    # start robots
    set ::StatusBarMsg "Running"
    set ::halted  0
    button_state disabled "Halt" halt_battle

    # Init
    init_game

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
    button_state disabled "Reset" reset_battle
}
#******

#****P* init_battle/halt_battle
#
# NAME
#
#   halt_battle
#
# DESCRIPTION
#
#   Halt a running match.
#
# SOURCE
#
proc halt_battle {} {
    set ::running 0
    set ::StatusBarMsg "Stopping battle"
    set ::halted 1

    button_state disabled "Reset" reset_battle
}
#******

#****P* init_battle/reset_battle
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
    set ::StatusBarMsg "Cleaning up"
    update

    foreach robot $::activeRobots {
        disable_robot $robot
    }
    if {$::parms(tkp)} {
        $::arena_c delete {*}[$::arena_c children 0]
    } else {
        $::arena_c delete all
    }
    grid forget $::game_f
    destroy $::game_f.health
    destroy $::game_f.msg
    grid $::sel_f -column 0 -row 2 -sticky nsew

    set ::StatusBarMsg "Select robot files for battle"
    button_state normal "Run Battle" {init_mode battle}
}
#******
