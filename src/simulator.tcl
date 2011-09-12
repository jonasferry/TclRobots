#****F* simulator/file_header
#
# NAME
#
#   simulator.tcl
#
# DESCRIPTION
#
#   This file contains the GUI description of the TclRobots simulator
#   mode.
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

#****P* simulator/init_sim
#
# NAME
#
#   init_sim
#
# DESCRIPTION
#
#   start the simulator
#
# SOURCE
#
proc init_sim {} {
    global game

    debug $::robotList

    # Read from robot file names; only the first file is used
    set game(robotfiles) [lindex $::robotList 0]

    set ticks   0
    set ::StatusBarMsg "Simulator"

    # Create and grid the simulation control box
    create_simctrl
    grid_sim_gui

    # show_arena is defined in gui.tcl
    show_arena

    # Clear message box
    set ::robotMsg {}

    # start robots
    set ::StatusBarMsg "Running Simulator"

    init_game

    set ::allRobots {r0 target}
    set ::activeRobots $::allRobots

    # Make target run a dummy program
    set ::data(target,code) {while {1} {set x [loc_x]}}
    set ::data(target,name) target
    set ::data(target,num)  12345

    # init_robots is defined in tclrobots.tcl
    init_match
    set ::tick 0

    # Set target signature, make it black and place it in center of the arena
    set ::data(target,num)   1
    set ::data(target,x)     500
    set ::data(target,y)     500

    # Start simulation in continous (non-step) mode
    set ::step 0

    # start robots
    set ::StatusBarMsg "Press START to start simulation"
    button_state "game" run_sim reset_sim
}
#******

#****P* init_battle/grid_sim_gui
#
# NAME
#
#   grid_sim_gui
#
# DESCRIPTION
#
#   Grid the simulator GUI.
#
# SOURCE
#
proc grid_sim_gui {} {
    global arena_c game_f robotMsg_lb sel_f sim_f

    grid forget $sel_f

    # The simulator shows the arena, the message box and the simulator
    # controls. Simulator controls are defined later.
    grid $game_f -column 0 -row 2 -sticky nsew
    grid $arena_c        -column 0 -row 0 -rowspan 2 -sticky nsew
    grid $sim_f -column 1 -row 0 -sticky nsew
    grid $robotMsg_lb    -column 2 -row 0            -sticky nsew
    grid columnconfigure $game_f 0 -weight 1
    grid rowconfigure    $game_f 0 -weight 1
    grid columnconfigure $game_f 1 -weight 1
    grid columnconfigure $game_f 2 -weight 1
}
#******

#****P* init_sim/create_simctrl
#
# NAME
#
#   create_simctrl
#
# DESCRIPTION
#
#   Create and grid the simulation control box.
#
# SOURCE
#
proc create_simctrl {} {
    global sim_f

    set  sim_f  [ttk::frame $::game_f.sim]

    # Create and grid first row of simulation control box
    set stepsys_cb [ttk::checkbutton $sim_f.cb -text "Step syscalls" \
                        -variable ::step -command {set ::do_step 1}]
    set step_b     [ttk::button $sim_f.step -text "Single Step" \
                        -command {set ::do_step 1}]
    set damage_b   [ttk::button $sim_f.damage -text "5% Hit" \
                        -command "incr ::data(r0,health) -5"]
    set ping_b     [ttk::button $sim_f.ping -text "Scan robot" \
                        -command "set ::data(r0,ping) 1"]
    set sep0_s     [ttk::separator $sim_f.sep0 -orient horizontal]

    grid $stepsys_cb -column 0 -row 0 -sticky nsew -columnspan 2
    grid $step_b     -column 2 -row 0 -sticky nsew -columnspan 2
    grid $damage_b   -column 0 -row 1 -sticky nsew -columnspan 2
    grid $ping_b     -column 2 -row 1 -sticky nsew -columnspan 2
    grid $sep0_s     -column 0 -row 2 -sticky nsew -columnspan 4

    # Limit the width of the entry fields in the status box
    set e_width 4
    set padding {0 0 4}

    set xstat_l     [ttk::label $sim_f.xl -text "X" -anchor e \
                         -padding $padding]
    set xstat_e     [ttk::entry $sim_f.xe -width $e_width \
                         -textvariable ::data(r0,x)]
    set ystat_l     [ttk::label $sim_f.yl -text "Y" -anchor e \
                         -padding {2 0}]
    set ystat_e     [ttk::entry $sim_f.ye -width $e_width \
                     -textvariable ::data(r0,y)]

    grid $xstat_l    -column 0 -row 3 -sticky nsew
    grid $xstat_e    -column 1 -row 3 -sticky nsew
    grid $ystat_l    -column 2 -row 3 -sticky nsew
    grid $ystat_e    -column 3 -row 3 -sticky nsew

    # Create bindings for user to set X and Y values manually
    bind  $xstat_e <Return> {
        ver_range x 0 999
        set ::data(r0,orgx)  $::data(r0,x)
        set ::data(r0,range) 0
    }
    bind  $xstat_e <Leave>  {
        ver_range x 0 999
        set ::data(r0,orgx)  $::data(r0,x)
        set ::data(r0,range) 0
    }
    bind  $ystat_e <Return> {
        ver_range y 0 999
        set ::data(r0,orgy)  $::data(r0,y)
        set ::data(r0,range) 0
    }
    bind  $ystat_e <Leave>  {
        ver_range y 0 999
        set ::data(r0,orgy)  $::data(r0,y)
        set ::data(r0,range) 0
    }

    # Create and grid second row of simulation status box
    set speedstat_l  [ttk::label $sim_f.sl -text "Speed" -anchor e \
                         -padding $padding]
    set speedstat_e  [ttk::entry $sim_f.se -width $e_width \
                          -textvariable ::data(r0,speed)]
    set hdgstat_l    [ttk::label $sim_f.hdl -text "Heading" -anchor e \
                         -padding $padding]
    set hdgstat_e    [ttk::entry $sim_f.hde -width $e_width \
                          -textvariable ::data(r0,hdg)]

    grid $speedstat_l  -column 0 -row 4 -sticky nsew
    grid $speedstat_e  -column 1 -row 4 -sticky nsew
    grid $hdgstat_l    -column 2 -row 4 -sticky nsew
    grid $hdgstat_e    -column 3 -row 4 -sticky nsew

    # Create bindings for user to set X and Y values manually
    bind  $speedstat_e <Return> {
        ver_range speed 0 100
        set ::data(r0,dspeed) $::data(r0,speed)
    }
    bind  $speedstat_e <Leave>  {
        ver_range speed 0 100
        set ::data(r0,dspeed) $::data(r0,speed)
    }
    bind  $hdgstat_e <Return> {
        ver_range hdg 0 359
        set ::data(r0,dhdg)  $::data(r0,hdg)
        set ::data(r0,range) 0
    }
    bind  $hdgstat_e <Leave>  {
        ver_range hdg 0 359
        set ::data(r0,dhdg)  $::data(r0,hdg)
        set ::data(r0,range) 0
    }

    # Create and grid third row of simulation status box
    set heatstat_l  [ttk::label $sim_f.htl -text "Heat" -anchor e \
                         -padding $padding]
    set heatstat_e  [ttk::entry $sim_f.hte -width $e_width \
                     -textvariable ::data(r0,heat)]
    set healthstat_l [ttk::label $sim_f.hthl -text "Health" -anchor e \
                         -padding $padding]
    set healthstat_e [ttk::entry $sim_f.hthe -width $e_width \
                          -textvariable ::data(r0,health)]

    grid $heatstat_l   -column 0 -row 5 -sticky nsew
    grid $heatstat_e   -column 1 -row 5 -sticky nsew
    grid $healthstat_l -column 2 -row 5 -sticky nsew
    grid $healthstat_e -column 3 -row 5 -sticky nsew

    # Create bindings for user to set Heat and Health values manually
    bind  $heatstat_e <Return> {
        ver_range heat 0 200
    }
    bind  $heatstat_e <Leave>  {
        ver_range heat 0 200
    }
    bind  $healthstat_e <Return> {
        ver_range health 0 $::parms(health)
    }
    bind  $healthstat_e <Leave>  {
        ver_range health 0 $::parms(health)
    }

    # Create and grid fourth row of simulation status box
    set tick0_l    [ttk::label $sim_f.t0 -text "Tick" -anchor e \
                         -padding $padding]
    set tick1_l    [ttk::label $sim_f.t1 -width $e_width \
                        -textvariable ::tick \
                        -relief sunken -borderwidth 1]
    set barrel0_l  [ttk::label $sim_f.b0 -text "Barrel" -anchor e \
                         -padding $padding]
    set barrel1_l  [ttk::label $sim_f.b1 -width $e_width \
                        -textvariable ::data(r0,btemp) \
                        -relief sunken -borderwidth 1]

    grid $tick0_l    -column 0 -row 6 -sticky nsew
    grid $tick1_l    -column 1 -row 6 -sticky nsew
    grid $barrel0_l  -column 2 -row 6 -sticky nsew
    grid $barrel1_l  -column 3 -row 6 -sticky nsew

    # Create and grid fifth row of simulation status box
    set lastsys0_l [ttk::label $sim_f.s0 -text "Syscall" -anchor e \
                         -padding $padding]
    set lastsys1_l [ttk::label $sim_f.s1 -width [* $e_width 3] \
                        -textvariable ::sim_syscall -anchor w \
                        -relief sunken -borderwidth 1]
    set sep1_s     [ttk::separator $sim_f.sep1 -orient horizontal]

    grid $lastsys0_l -column 0 -row 7 -sticky nsew
    grid $lastsys1_l -column 1 -row 7 -sticky nsew -columnspan 3
    grid $sep1_s     -column 0 -row 8 -sticky nsew -columnspan 4

    # Create and grid third row of simulation control box
    set ::status_var {}
    set ::status_val {}

    set var_l      [ttk::label $sim_f.vrl -text "Variable"]
    set var_e      [ttk::entry $sim_f.vre -width $e_width \
                        -textvariable ::status_var]
    set val_l      [ttk::label $sim_f.vll -text "Value"]
    set val_e      [ttk::entry $sim_f.vle -width $e_width \
                        -textvariable ::status_val]
    set examine_b  [ttk::button $sim_f.xb -text "Examine" -command examine]
    set set_b      [ttk::button $sim_f.sb -text "Set" -command setval]

    grid $var_l      -column 0 -row 9  -sticky nsew
    grid $var_e      -column 1 -row 9  -sticky nsew -columnspan 2
    grid $examine_b  -column 3 -row 9  -sticky nsew
    grid $val_l      -column 0 -row 10 -sticky nsew
    grid $val_e      -column 1 -row 10 -sticky nsew -columnspan 2
    grid $set_b      -column 3 -row 10 -sticky nsew

    bind $var_e <Key-Return> "$examine_b invoke"
    bind $val_e <Key-Return> "$set_b     invoke"

    # Make the simulation control box resizable
    for {set i 0} {$i < 3} {incr i} {
        grid columnconfigure $sim_f $i -weight 1
    }
}
#******

#****P* create_simctrl/ver_range
#
# NAME
#
#   ver_range
#
# DESCRIPTION
#
#   Verify range of an entry for simulated robot.
#
# SOURCE
#
proc ver_range {var low high} {
    set val $::data(r0,$var)
    if {$val < $low} {
        set val $low
    }
    if {$val > $high} {
        set val $high
    }
    set ::data(r0,$var) $val
}
#******

#****P* create_simctrl/examine
#
# NAME
#
#   examine
#
# DESCRIPTION
#
#   Examine a variable in the simulated robot.
#
# SOURCE
#
proc examine {} {
    puts $::data(r0,interp)
    set ::status_val [$::data(r0,interp) eval set $::status_var]
    puts $::status_val
}
#******

#****P* create_simctrl/setval
#
# NAME
#
#   setval
#
# DESCRIPTION
#
#   Set a variable in the simulated robot.
#
# SOURCE
#
proc setval {} {
    $::data(r0,interp) eval set $::status_var $::status_val
}
#******

#****P* init_sim/run_sim
#
# NAME
#
#   run_sim
#
# DESCRIPTION
#
#   Run simulation.
#
# SOURCE
#
proc run_sim {} {
    global game

    button_state "running"

    # Start simulation
    set game(state) "run"

    # gui_init_robots is defined in gui.tcl. Make target black.
    gui_init_robots 1

    # act and tick are defined in tclrobots.tcl
    act
    tick

    # Procedure run_robots is found in tclrobots.tcl
    coroutine run_robotsCo run_robots
}
#******

#****P* halt_sim/reset_sim
#
# NAME
#
#   reset_sim
#
# DESCRIPTION
#
#   Reset to file select state.
#
# SOURCE
#
proc reset_sim {} {
    global activeRobots arena_c game game_f parms sel_f sim_f \
	StatusBarMsg

    set StatusBarMsg "Cleaning up"

    set game(state) "halt"
    update
    destroy $sim_f

    foreach robot $activeRobots {
        disable_robot $robot
    }
    if {$parms(tkp)} {
        $arena_c delete {*}[$arena_c children 0]
    } else {
        $arena_c delete all
    }
    grid forget $game_f
    grid $sel_f -column 0 -row 2 -sticky nsew

    button_state "file"
}
#******
