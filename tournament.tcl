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
    get_filenames_tourn
    init_gui_tourn

    # Init robots
    init

    # Init robots on GUI
    gui_init_robots

    if 0 {
        # Start game
        run_tourn

        # find winnner
        button_state disabled "Reset" reset
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
#   Creates the tournament mode GUI.
#
# SOURCE
#
proc init_gui_tourn {} {
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

    # Create and grid the tournament control box
    create_tournctrl

    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}

    # start robots
    set ::StatusBarMsg "Running"
    set ::halted  0
    button_state disabled "Halt" halt
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
    set  tourn_f [ttk::frame $::game_f.tourn]
    grid $tourn_f -column 2 -row 0 -rowspan 2 -sticky nsew

    set tournctrl0_f [ttk::frame $tourn_f.f0 -relief raised -borderwidth 2]
    set start_b     [ttk::button $tourn_f.f0.start -text "Start Tournament" \
                         -command run_tourn]
    set end_b       [ttk::button $tourn_f.f0.end -text "Close" \
                         -command end_tourn]

    grid $start_b -column 0 -row 0 -sticky nsew
    grid $end_b   -column 1 -row 0 -sticky nsew

    set ::tournScore    {}
    set tournScore_lb   [listbox $::game_f.tourn.s -listvariable ::tournScore]

    set ::tournMatches  {}
    set tournMatches_lb [listbox $::game_f.tourn.m -listvariable ::tournMatches]

    set tournctrl1_f [ttk::frame $tourn_f.f1 -relief raised -borderwidth 2]
    set tourntime_l  [ttk::label $tourn_f.f1.l \
                          -text "Maximum minutes per match:"]
    set tourntime_e  [ttk::entry $tourn_f.f1.e \
                          -textvariable tlimit]

    grid $tourntime_l -column 0 -row 0 -sticky nsew
    grid $tourntime_e -column 0 -row 1 -sticky nsew

    set tournctrl2_f [ttk::frame $tourn_f.f2 -relief raised -borderwidth 2]
    set tournfile_l  [ttk::label $tourn_f.f2.l \
                          -text "Optional results filename:"]
    set tournfile_e  [ttk::entry $tourn_f.f2.e \
                          -textvariable outfile]

    grid $tournfile_l -column 0 -row 0 -sticky nsew
    grid $tournfile_e -column 0 -row 1 -sticky nsew

    grid $tournctrl0_f     -column 0 -row 0 -sticky nsew
    grid $tournScore_lb    -column 0 -row 1 -sticky nsew
    grid $tournMatches_lb  -column 0 -row 2 -sticky nsew
    grid $tournctrl1_f     -column 0 -row 3 -sticky nsew
    grid $tournctrl2_f     -column 0 -row 4 -sticky nsew
    

    if 0 {
    # Create and grid first row of simulation control box
    set simctrl0_f [ttk::frame $sim_f.f0 -relief raised -borderwidth 2]
    set stepsys_cb [ttk::checkbutton $sim_f.f0.cb -text "Step syscalls" \
                        -variable ::step -command {set ::do_step 1}]
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
    set speedstat_l  [ttk::label $sim_f.f1.sl   -text "Speed"]
    set speedstat_e  [ttk::entry $sim_f.f1.se   -width $e_width \
                          -textvariable ::data(r0,speed)]
    set hdgstat_l    [ttk::label $sim_f.f1.hdl  -text "Heading"]
    set hdgstat_e    [ttk::entry $sim_f.f1.hde  -width $e_width \
                          -textvariable ::data(r0,hdg)]
    set healthstat_l [ttk::label $sim_f.f1.hthl -text "Health"]
    set healthstat_e [ttk::entry $sim_f.f1.hthe -width $e_width \
                          -textvariable ::data(r0,health)]

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
    set lastsys0_l [ttk::label $sim_f.f1.s0 -text "Last syscall:"]
    set lastsys1_l [ttk::label $sim_f.f1.s1 -width [* $e_width 3] \
                        -textvariable ::sim_syscall -anchor w]
    set tick0_l    [ttk::label $sim_f.f1.t0 -text "Tick:"]
    set tick1_l    [ttk::label $sim_f.f1.t1 -width $e_width \
                        -textvariable ::tick]
    set barrel0_l  [ttk::label $sim_f.f1.b0 -text "Barrel:"]
    set barrel1_l  [ttk::label $sim_f.f1.b1 -width $e_width \
                        -textvariable ::data(r0,btemp)]

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

    grid columnconfigure $sim_f 0 -weight 1






    # Start game
    run_tourn

    # find winnner
    button_state disabled "Reset" reset
}
}

#****P* create_tournctrl/end_tourn
#
# NAME
#
#   end_tourn
#
# DESCRIPTION
#
#   End tournament.
#
# SOURCE
#
proc end_tourn {} {
    set ::running 0
    set ::halted 1
    # reset is defined in battle.tcl
    reset
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
    set ::robotHealth {}
    set index 0
    foreach robot $::allRobots {
        lappend ::robotHealth "[format %3d $::data($robot,health)] $::data($robot,name)  ($::data($robot,inflicted))"
        $::robotHealth_lb itemconfigure $index -foreground $::data($robot,color)
        if {$::data($robot,brightness) > 0.5} {
            $::robotHealth_lb itemconfigure $index -background black
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
    set ::robotHealth {}
    set index 0
    foreach robot $::allRobots {
        lappend ::robotHealth "[format %3d $::data($robot,health)] $::data($robot,name)  ($::data($robot,inflicted))"
        $::robotHealth_lb itemconfigure $index -foreground $::data($robot,color)
        if {$::data($robot,brightness) > 0.5} {
            $::robotHealth_lb itemconfigure $index -background black
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
    foreach robot $::allRobots {
        foreach target $allRobots {
            if {$robot eq $target} {
                continue
            }
            puts "running"
            set ::running 1
            coroutine run_robotsCo run_robots
            vwait ::running
            puts "activerobots: $::activeRobots"
        }
    }
}
#******

#OLD TOURNAMENT CODE FOLLOWS, USED FOR PLUNDERING

if 0 {

###############################################################################
#
# reset2 to tournament controller
#
#

proc reset2 {} {
  global execCmd
  .c delete all
  set execCmd start
  .f1.b1 configure -text "Run Battle" 
  pack forget .c
  pack .f2 -side top -expand 1 -fill both
  .l configure -text "Select robot files for battle" -fg black
  .f1.b1 configure -state disabled
  .f1.b2 configure -state disabled
  .f1.b3 configure -state disabled
  .f1.b4 configure -state disabled
  .f1.b5 configure -state disabled
  .tourn.f1.start configure -state normal 
  .tourn.f1.end   configure -state normal 
  .tourn.f2.t     configure -state normal 
  .tourn.f3.f     configure -state normal 
}



###############################################################################
#
# list compare function for "int string"
#
#

proc lcomp {l1 l2} {
  set i1 [lindex $l1 0]
  set i2 [lindex $l2 0]
  if {$i1 < $i2} {
    return -1
  } elseif {$i1 > $i2} {
    return  1
  } else {
    return  0
  }
}  


###############################################################################
#
# append a string to a file
#
#

proc write_file {file str} {
  set fd [open $file a]
  puts $fd $str
  close $fd
}


###############################################################################
#
# check time limit of match
#
#

proc check_time {} {
  global ticks maxticks running nowin
  if {$ticks > $maxticks} {set running 0; return} 
  if {$nowin} return
  # update every 30 seconds
  if {$ticks % 60 == 0} {
    # assumes 500 ms tick rate!
    set left [expr ($maxticks-$ticks)/2]
    set mins [expr $left/60]
    set secs [expr $left%60]
    .tourn.f4.l configure -text "Time remaining: [format {%d:%02d} $mins $secs]"
  }
}


###############################################################################
#
# start the tournament 
#
#

proc do_tourn {} {
  global rob1 rob2 rob3 rob4 parms running halted ticks maxticks execCmd 
  global tlimit outfile numList finish

  set finish ""
  set running 0
  set halted  0
  set ticks   0

  set robots ""
  .tourn.f4.lst delete 0 end

  if {[catch {set tlimit [expr round($tlimit)]}] == 1} {
    .tourn.f4.l configure -text \
	    "Maximum time limit must be numeric"
    return  
  }

  # get robot filenames from window
  set robots ""
  set lst .f2.fr.l1
  set i $numList
  
  # get unique robot files
  for {set i 1} {$i <= $numList} {incr i} {
    set rob [$lst get [expr $i - 1]]
    if {[lsearch -exact $robots $rob] == -1} {
      lappend robots $rob
    }
  }

  set dot_geom [winfo geom .]
  set dot_geom [split $dot_geom +]
  set dot_x [lindex $dot_geom 1]
  set dot_y [lindex $dot_geom 2]

  set num_bots [llength $robots]
  if {$num_bots < 2} {
    .l configure  -text \
      "Must have at least two unique files selected to run tournament"
    return
  }
  
  set results ""
  foreach idx $robots  {
    set f [file tail $idx]
    lappend save_robots $f
    set tourney($f)     0
  }

  
  set tot_matches  [expr (($num_bots * $num_bots) - $num_bots) / 2]
  set cur_match    0
  .tourn.f4.l configure -text "$tot_matches matches to run"

  .tourn.f1.start configure -state disabled
  .tourn.f1.end   configure -state disabled
  .tourn.f2.t     configure -state disabled
  .tourn.f3.f     configure -state disabled

  .l configure -text "Running Tournament"
  set execCmd halt
  .f1.b1 configure -state normal    -text "Halt"
  pack forget .f2
  pack .c -side top -expand 1 -fill both


  while {[llength $robots] > 1} {  
    set current [lindex $robots 0]
    set robots  [lrange $robots 1 end]
    .c delete all
    draw_arena
    foreach rr $robots {
      # clean up robots
      foreach robx {rob1 rob2 rob3 rob4} {
	upvar #0 $robx r
	set r(status) 0
	set r(mstate) 0
	set r(name)   ""
	set r(pid)    -1
      }

      set colors $parms(colors)
      set quads  $parms(quads)
      set numbots 4
      # pick random starting quadrant, colors and init robots
      set i 1
      foreach f "$current $rr" {
	set n [rand $numbots]
	set color [lindex $colors $n]
	set colors [lreplace $colors $n $n]
	set n [rand $numbots]
	set quad [lindex $quads $n]
	set quads [lreplace $quads $n $n]

	set x [expr [lindex $quad 0]+[rand 300]]
	set y [expr [lindex $quad 1]+[rand 300]]
	
	set winx [expr $dot_x+540]
	set winy [expr $dot_y+(($i-1)*145)]

	set rc [robot_init rob$i $f $x $y $winx $winy $color]

	if {$rc == 0} {
	  oops rob$i
	  clean_up
	  reset2
	  # .f1.b1 configure -state normal -text "Reset"
	  .tourn.f1.start configure -state normal 
	  .tourn.f1.end   configure -state normal 
	  .tourn.f2.t     configure -state normal 
	  .tourn.f3.f     configure -state normal 
	  return
	}

	incr i
	incr numbots -1
      }

      # start robots
      incr cur_match
      .l configure -text "Running Match $cur_match of $tot_matches"
      set execCmd halt
      .f1.b1 configure -state normal    -text "Halt"
      .f1.b2 configure -state disabled
      .f1.b3 configure -state disabled
      .f1.b4 configure -state disabled
      .f1.b5 configure -state disabled

      start_robots

      # start physics package
      show_robots
      set running 1
      set ticks 0
      set maxticks [expr int(($tlimit*60)/($parms(simtick)/1000.0)+1)]
      check_time
      every $parms(tick) update_robots {$running}
      every $parms(tick) check_time    {$running}

      tkwait variable running

      .l configure -text "Match over"
      update

      # shutdown all spawned wishes
      set i 1
      foreach ff "rob1 rob2" {
	upvar #0 rob$i r
	if {$r(status)} {
	  disable_robot rob$i 0
	}
	kill_robot rob$i
	incr i
      }

      # check for halted
      if {$halted} {
	.l configure -text "Tournament halted"
	set execCmd reset2
	.f1.b1 configure -state normal -text "Reset"
	return
      }

      # find winnner rob1=t_current rob2=t_rr
      set t_current [file tail $current]
      set t_rr      [file tail $rr     ]
      if {$rob1(damage)<100 && $rob2(damage)==100} {
        set res "$t_current vs. $t_rr : $t_current ($rob1(damage)%) wins"
        incr tourney($t_current) 3 
      } elseif {$rob1(damage)==100 && $rob2(damage)<100} {
        set res "$t_current vs. $t_rr : $t_rr ($rob2(damage)%) wins"
        incr tourney($t_rr) 3
      } else {
        set res \
 "$t_current vs. $t_rr : tie $t_current ($rob1(damage)%) $t_rr ($rob2(damage)%)"
        incr tourney($t_current) 
	incr tourney($t_rr)
      }
      .tourn.f4.lst insert end $res
      append results  $res \n
      .tourn.f4.lst yview [expr $cur_match-4 > 0 ? $cur_match-4 : 0]
      .c delete all
      draw_arena
      update
    
    }

  }

  # rank results
  append results \n \n results \n \n
  foreach n [array names tourney] {
    lappend resList "$tourney($n)  $n"
  }
  set resList [lsort -decreasing -command lcomp $resList]
  foreach l $resList {
    append results2 $l \n
  }
  .tourn.f4.lst insert end "" "" "results"  
  foreach l [split $results2 \n] {
    .tourn.f4.lst insert end $l
  }

  # save results to file
  if {$outfile != ""} {
    catch {write_file $outfile $results\n$results2}
  }

  set execCmd reset2
  # .f1.b1 configure -state normal -text "Reset"
  .tourn.f1.start configure -state normal 
  .tourn.f1.end   configure -state normal 
  .tourn.f2.t     configure -state normal 
  .tourn.f3.f     configure -state normal 

}

###############################################################################
#
# start the tournament controller
#
#

proc tournament {} {
  global rob1 rob2 rob3 rob4 parms running halted ticks execCmd 
  global tlimit outfile numList 

  set running 0
  set halted  0
  set ticks   0
  .l configure -text "Tournament"

  set dot_geom [winfo geom .]
  set dot_geom [split $dot_geom +]
  set dot_x [lindex $dot_geom 1]
  set dot_y [lindex $dot_geom 2]

  .l configure -text "Running Tournament"
  set execCmd reset
  .f1.b1 configure -state disabled
  .f1.b2 configure -state disabled
  .f1.b3 configure -state disabled
  .f1.b4 configure -state disabled
  .f1.b5 configure -state disabled


  # make a toplevel icon window, iconwindow doesn't have transparent bg :-(
  catch {destroy .icont}
  toplevel .icont
  pack [label .icont.i -image iconfn]

  # create toplevel tournament window
  catch {destroy .tourn}
  toplevel .tourn
  wm title .tourn "Tournament Controller"
  wm iconwindow .tourn .icont
  wm iconname .tourn "TclRobots Tourney"
  wm group .tourn .
  wm group . .tourn 
  wm protocol .tourn WM_DELETE_WINDOW "catch {.tourn.f1.end invoke}"
  set i 3
  set dot_geom [winfo geom .]
  set dot_geom [split $dot_geom +]
  set dot_x [lindex $dot_geom 1]
  set dot_y [lindex $dot_geom 2]
  set winx [expr $dot_x+540]
  set winy [expr $dot_y+(($i-1)*145)]
  wm geom .tourn +${winx}+$winy
  wm minsize .tourn 220 180
  frame .tourn.f1 -relief raised -borderwidth 2
  button .tourn.f1.start -text " Start Tournament " -command do_tourn
  button .tourn.f1.end -text " Close  " \
     -command "set halted 1; clean_up; reset; destroy .tourn"
  pack .tourn.f1.start .tourn.f1.end -expand 1 -side left -pady 5 -padx 1

  frame .tourn.f2 -relief raised -borderwidth 2
  label .tourn.f2.l1 -text "Maximum minutes per match:" -anchor e -width 25
  entry .tourn.f2.t -width 5 -textvariable tlimit -width 5 -relief sunken
  pack  .tourn.f2.l1 .tourn.f2.t -side left -pady 5 -padx 1
  # override binding for Any-Keypress, but save others
  foreach e {.tourn.f2.t} {
    set cur_bind [bind Entry]
    foreach c $cur_bind {
      bind $e $c "[bind Entry $c] ; return -code break"
    }
    bind $e <KeyPress> {num_only %W %A}
  }
 
  frame .tourn.f3 -relief raised -borderwidth 2
  label .tourn.f3.l2 -text "Optional results filename:"  -anchor e -width 25
  entry .tourn.f3.f -width 5 -textvariable outfile -width 14 -relief sunken
  pack  .tourn.f3.l2 .tourn.f3.f -side left -pady 5 -padx 1


  frame .tourn.f4 
  label .tourn.f4.l -text "" -relief raised -borderwidth 2
  label .tourn.f4.lb -text Results -relief raised -borderwidth 2
  listbox .tourn.f4.lst -yscrollcommand ".tourn.f4.scr set" \
                        -xscrollcommand ".tourn.f4.scx set" \
                        -relief sunken
  scrollbar .tourn.f4.scr -command ".tourn.f4.lst yview"
  scrollbar .tourn.f4.scx -command ".tourn.f4.lst xview" -orient horizontal
  pack .tourn.f4.l -side top -fill x
  pack .tourn.f4.lb -side top -fill x
  pack .tourn.f4.scr -side right -fill y
  pack .tourn.f4.scx -side bottom -fill x
  pack .tourn.f4.lst -side left -fill both -expand 1

  pack .tourn.f1 .tourn.f2  .tourn.f3 .tourn.f4 -side top -fill x

}
}