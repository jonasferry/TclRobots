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
    if {$::gui} {
        get_filenames_tourn
        init_gui_tourn
    }

    # Init all robots, can't use init_game from tclrobots.tcl because
    # interpreters should be initialised separately in tournament mode
    init_parms
    init_trig_tables
    init_rand
    init_files
    init_robots

    if {$::gui} {
        # Give the robots colors
        set colors [distinct_colors [llength $::allRobots]]

        foreach robot $::allRobots current_color $colors {
            # Set colors as far away as possible from each other visually
            set ::data_tourn($robot,color)      $current_color
            set ::data_tourn($robot,brightness) [brightness $current_color]
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
    set ::tournScore_lb   [listbox $::game_f.tourn.s \
                               -listvariable ::tournScore]

    set ::tournMatches  {}
    set ::tournMatches_lb [listbox $::game_f.tourn.m \
                               -listvariable ::tournMatches]

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

    grid $tournctrl0_f      -column 0 -row 0 -sticky nsew
    grid $::tournScore_lb   -column 0 -row 1 -sticky nsew
    grid $::tournMatches_lb -column 0 -row 2 -sticky nsew
    grid $tournctrl1_f      -column 0 -row 3 -sticky nsew
    grid $tournctrl2_f      -column 0 -row 4 -sticky nsew
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
    destroy $::game_f.tourn
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
    set ::tournScore {}
    foreach robot $::allRobots_tourn {
        lappend ::tournScore "[format %3d $::score($robot)] $::data($robot,name)"
#        debug "tournScore: $::tournScore"
#        set index [lsearch -exact $::tournScore $::data($robot,name)]
#        debug "show_score index $::data($robot: $index"
#        lreplace $::tournScore [- $index 1] $index \
#            "[format %3d $::score($robot)] $::data($robot,name)"
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
#        $::tournMatches_lb itemconfigure $index -foreground $::data($robot,color)
#        if {$::data($robot,brightness) > 0.5} {
#            $::robotHealth_lb itemconfigure $index -background black
#        }
#        incr index
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
        data data_tourn running matchlist score matchlog outfile

    foreach robot $allRobots {
        set score($robot) 0
    }
    build_matchlist

    # Remember allRobots, activeRobots and data
    set allRobots_tourn    $allRobots
    set activeRobots_tourn $activeRobots
    array set data_tourn   [array get data]

    # Figure out the longest robot name to line up the report nicely
    set ::long_name 0
    foreach name [array names data *,name] {
        if {[string length $data($name)] > $::long_name} {
            set ::long_name [string length $data($name)]
        }
    }
    set matchlog ""

    foreach match $matchlist {
        set robot  [lindex $match 0]
        set target [lindex $match 1]

        # Switch all and active robots to current tournament pair
        set allRobots    "$robot $target"
        set activeRobots $allRobots

        # Init current two robots' interpreters
        init_robots
        init_interps

        set running 1

        if {$::gui} {
            # Init robots on GUI
            gui_init_robots

            set data($robot,color)      $data_tourn($robot,color)
            set data($robot,brightness) $data_tourn($robot,brightness)

            # Set initial colors
            foreach robot $allRobots {
                set data($robot,color)      $data_tourn($robot,color)
                set data($robot,brightness) $data_tourn($robot,brightness)
            }
            update_tourn
        }
        set ::stopped 0
        coroutine run_robotsCo run_robots
        vwait ::stopped

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
            foreach robot $activeRobots {
                incr score($robot) 1
            }
            append match_msg \
                "$data($robot,name)    vs $data($target,name) (tie)"
        }
        if {$::gui} {
            update_tourn
        }
        puts $match_msg log
        append matchlog "$match_msg\n"

        # Disable robots and clear messages
        foreach robot $activeRobots {
            disable_robot $robot
            set ::robotMsg {}
        }
    }
    # Switch back all and active robots to remembered values
    set allRobots    $allRobots_tourn
    set activeRobots $activeRobots_tourn

    # Sort the scores
    set score_sorted {}
    foreach robot $allRobots {
        lappend score_sorted "$robot $score($robot)"
    }
    set ::win_msg "TOURNAMENT SCORE:\n"
    set place 1
    foreach robotscore [lsort -integer -index 1 \
                            -decreasing $score_sorted] {
        set robot [lindex $robotscore 0]
        append ::win_msg "[format %3d $score($robot)] $data($robot,name)\n"
        incr place
    }
    # show results
    if {$::gui} {
        if {$::halted} {
            set ::StatusBarMsg "Battle halted"
        } else {
            tk_dialog2 .winner "Results" $::win_msg "-image iconfn" 0 dismiss
        }
        button_state disabled "Reset" reset
    } else {
        puts "\n$::win_msg" log
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

#****P* run_tourn/build_matchlist
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