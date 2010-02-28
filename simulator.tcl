

###############################################################################
#
# examine a variable
#
#

proc examine {} {
    puts $::data(r0,interp)
    set ::status_val [$::data(r0,interp) eval set $::status_var]
    puts $::status_val
#    exit;

    #set ::status_val [$::data(r0,interp) eval {set dir}]
    #puts "status_val: $::status_val";exit
#    interp alias {}  targetPath targetCmd
}

###############################################################################
#
# set a variable
#
#

proc setval {} {
    $::data(r0,interp) eval set $::status_var $::status_val
}

proc sim_robot {} {
    while {$::running == 1} {
        # Reset health of target
        set ::data(target,health) $::parms(health)

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

        set ::sim_syscall $::data(r0,syscall,$::tick)

        act

        if {$::data(r0,sysreturn,$::tick) ne ""} {
            lappend ::sim_syscall "=>" $::data(r0,sysreturn,$::tick)
        }

        update_robots

        # GUI
        show_robots
        show_scan
        show_health

        tick

        if {$::step} {
            vwait ::do_step
            set ::do_step 0
        }

        after $::parms(tick) [info coroutine]
        yield
    }
}

###############################################################################
#
# verify range of an rob1 entry for simulator
#
#

proc ver_range {var low high} {
    set val $::data(r0,$var)
    if {$val < $low}  { set $var $low } 
    if {$val > $high} { set $var $high } 
    set ::data(r0,$var) $val
}

proc end_sim {} {
    # Restore canvas when simulation control no longer need space
    grid configure $::arena_c -rowspan 2
    exit
}

###############################################################################
#
# start the simulator
#
#

proc init_sim {} {
    # Read from robot file name from window; only the first file is used
    set lst [$::robotlist_lb get 0]
    if {[llength $lst] == 0} {
        return
    }

    set halted  0
    set ticks   0
    set ::StatusBarMsg "Simulator"

    grid forget $::sel_f
#    grid forget $::robotHealth_lb
#    grid forget $::robotMsg_lb
#    grid $::robotMsg_lb -column 1 -row 0
    grid $::game_f -column 0 -row 2 -sticky nsew
    show_arena

    puts check

    # start robots
    set ::StatusBarMsg "Running Simulator"

    $::run_b   configure -state disabled -command reset
    $::sim_b   configure -state disabled
    $::tourn_b configure -state disabled
    $::about_b configure -state disabled
    $::quit_b  configure -state disabled

    init

    set ::tick 0

    set ::allRobots {r0 target}

    set f [open [lindex $lst 0]]
    set ::data(r0,code) [read $f]
    close $f

    set ::data(target,code) {while {1} {set x [loc_x]}}

    set ::activeRobots $::allRobots

    init_robots

    # Set target signature, make it black and place it in center of the arena
    set ::data(target,num)   1
    set ::data(target,x)     500
    set ::data(target,y)     500

    gui_init_robots 1

    act
    tick

    # Make room for simulation controls
    grid configure $::arena_c -rowspan 3

    # Create and grid the simulation control box
    set  sim_f      [ttk::frame $::game_f.sim]
    grid $sim_f     -column 1 -row 1 -sticky nsew

    # Create and grid first row of simulation control box
    set simctrl0_f [ttk::frame $sim_f.f0 -relief raised -borderwidth 2]
    set stepsys_cb [ttk::checkbutton $sim_f.f0.cb -text "Step syscalls" \
                        -variable ::step]
    set step_b     [ttk::button $sim_f.f0.step -text "Single Step" \
                        -command {set ::do_step 1}]
    set damage_b   [ttk::button $sim_f.f0.damage -text "5% Hit" \
                        -command "incr ::data(r0,health) -5"]
    set ping_b     [ttk::button $sim_f.f0.ping -text "Scan" \
                        -command "set ::data(r0,ping) 1"]
    set end_b      [ttk::button $sim_f.f0.end -text "Close" \
                        -command end_sim]

    grid $simctrl0_f -column 0 -row 0 -sticky nsew
    grid $stepsys_cb -column 0 -row 0 -sticky nsew
    grid $step_b     -column 1 -row 0 -sticky nsew
    grid $damage_b   -column 2 -row 0 -sticky nsew
    grid $ping_b     -column 3 -row 0 -sticky nsew
    grid $end_b      -column 4 -row 0 -sticky nsew

    # Create and grid second row of simulation control box
    # This frame contains three rows of status data
    # This is the first row of simulation status box

    # Limit the width of the entry fields in the status box
    set e_width 4

    set simctrl1_f  [ttk::frame $sim_f.f1     -relief raised -borderwidth 2]
    set xstat_l     [ttk::label $sim_f.f1.xl  -text "X"]
    set xstat_e     [ttk::entry $sim_f.f1.xe  -width $e_width \
                         -textvariable ::data(r0,x)]
    set ystat_l     [ttk::label $sim_f.f1.yl  -text "Y"]
    set ystat_e     [ttk::entry $sim_f.f1.ye  -width $e_width \
                     -textvariable ::data(r0,y)]
    set heatstat_l  [ttk::label $sim_f.f1.htl -text "Heat"]
    set heatstat_e  [ttk::entry $sim_f.f1.hte -width $e_width \
                     -textvariable ::data(r0,heat)]

    grid $simctrl1_f -column 0 -row 1 -sticky nsew
    grid $xstat_l    -column 0 -row 0 -sticky nsew
    grid $xstat_e    -column 1 -row 0 -sticky nw
    grid $ystat_l    -column 2 -row 0 -sticky nsew
    grid $ystat_e    -column 3 -row 0 -sticky nw
    grid $heatstat_l -column 4 -row 0 -sticky nsew
    grid $heatstat_e -column 5 -row 0 -sticky nw

    # Create bindings for user to set X, Y and Heat values manually
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
    bind  $heatstat_e <Return> {
        ver_range heat 0 200
    }
    bind  $heatstat_e <Leave>  {
        ver_range heat 0 200
    }

    # Create and grid second row of simulation status box
    #set simctrl2_f   [ttk::frame $sim_f.f2     -relief raised -borderwidth 2]
    set speedstat_l  [ttk::label $sim_f.f1.sl   -text "Speed"]
    set speedstat_e  [ttk::entry $sim_f.f1.se   -width $e_width \
                          -textvariable ::data(r0,speed)]
    set hdgstat_l    [ttk::label $sim_f.f1.hdl  -text "Heading"]
    set hdgstat_e    [ttk::entry $sim_f.f1.hde  -width $e_width \
                          -textvariable ::data(r0,hdg)]
    set healthstat_l [ttk::label $sim_f.f1.hthl -text "Health"]
    set healthstat_e [ttk::entry $sim_f.f1.hthe -width $e_width \
                          -textvariable ::data(r0,health)]

    #grid $simctrl2_f   -column 0 -row 2 -sticky nsew
    grid $speedstat_l  -column 0 -row 1 -sticky nsew
    grid $speedstat_e  -column 1 -row 1 -sticky nw
    grid $hdgstat_l    -column 2 -row 1 -sticky nsew
    grid $hdgstat_e    -column 3 -row 1 -sticky nw
    grid $healthstat_l -column 4 -row 1 -sticky nsew
    grid $healthstat_e -column 5 -row 1 -sticky nw

    # Create bindings for user to set X, Y and Heat values manually
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
    bind  $healthstat_e <Return> {
        ver_range health 0 $::parms(health)
    }
    bind  $healthstat_e <Leave>  {
        ver_range health 0 $::parms(health)
    }

    # Create and grid third row of simulation status box
    #set simctrl3_f [ttk::frame $sim_f.f3    -relief raised -borderwidth 2]
    set lastsys0_l [ttk::label $sim_f.f1.s0 -text "Last syscall:"]
    set lastsys1_l [ttk::label $sim_f.f1.s1 -width [* $e_width 3] \
                        -textvariable ::sim_syscall -anchor w]
    set tick0_l    [ttk::label $sim_f.f1.t0 -text "Tick:"]
    set tick1_l    [ttk::label $sim_f.f1.t1 -width $e_width \
                        -textvariable ::tick]
    set barrel0_l  [ttk::label $sim_f.f1.b0 -text "Barrel:"]
    set barrel1_l  [ttk::label $sim_f.f1.b1 -width $e_width \
                        -textvariable ::data(r0,btemp)]

    #grid $simctrl3_f -column 0 -row 3 -sticky nsew
    grid $lastsys0_l -column 0 -row 2 -sticky nsew
    grid $lastsys1_l -column 1 -row 2 -sticky nwe
    grid $tick0_l    -column 2 -row 2 -sticky nsew
    grid $tick1_l    -column 3 -row 2 -sticky nw
    grid $barrel0_l  -column 4 -row 2 -sticky nsew
    grid $barrel1_l  -column 5 -row 2 -sticky nw

    # Create and grid third row of simulation control box
    set ::status_var {}
    set ::status_val {}

    set simctrl2_f [ttk::frame $sim_f.f2     -relief raised -borderwidth 2]
    set var_l      [ttk::label $sim_f.f2.vrl -text "Variable:"]
    set var_e      [ttk::entry $sim_f.f2.vre \
                        -textvariable ::status_var]
    set val_l      [ttk::label $sim_f.f2.vll -text "Value:"]
    set val_e      [ttk::entry $sim_f.f2.vle -width $e_width \
                        -textvariable ::status_val]
    set examine_b  [ttk::button $sim_f.f2.xb -text "Examine" -command examine]
    set set_b      [ttk::button $sim_f.f2.sb -text "Set" -command setval]

    grid $simctrl2_f -column 0 -row 2 -sticky nsew
    grid $var_l      -column 0 -row 0 -sticky nsew
    grid $var_e      -column 1 -row 0 -sticky nsew
    grid $val_l      -column 2 -row 0 -sticky nsew
    grid $val_e      -column 3 -row 0 -sticky nsew
    grid $examine_b  -column 4 -row 0 -sticky nsew
    grid $set_b      -column 5 -row 0 -sticky nsew

    bind $var_e <Key-Return> "$examine_b invoke"
    bind $val_e <Key-Return> "$set_b     invoke"

    # Make the simulation control box resizable
    foreach w [winfo children $sim_f] {
        grid columnconfigure $w 0 -weight 1
        for {set i 0} {$i < 6} {incr i} {
            grid columnconfigure $w $i -weight 1
        }
    }



    if 0 {
    for {set i 0} {$i < 6} {incr i} {
        grid columnconfigure $sim_f.f2 $i -weight 1
    }
    }

    grid columnconfigure $sim_f 0 -weight 1

    # Start simulation
    set ::running 1
    set ::step 0
    coroutine sim_robotCo sim_robot
    vwait ::running
    puts "activerobots: $::activeRobots"

    if 0 {
    set step 1

    # override binding for Any-Keypress, but save others
    foreach e {.debug.f2.x .debug.f2.y .debug.f2.h .debug.fb.s \
                   .debug.fb.h .debug.fb.d} {
        set cur_bind [bind Entry]
        foreach c $cur_bind {
            bind $e $c "[bind Entry $c] ; return -code break"
        }
        bind $e <KeyPress> {num_only %W %A}
    }

    # set initial step state
    #do_step
    sim
}

}
