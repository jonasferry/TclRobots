package require Tk

set parms(colors) {SeaGreen3 IndianRed3 orchid3 SlateBlue1}

###############################################################################
#
# about box
#
#

proc about {} {
  tk_dialog2 .about "About TclRobots" "TclRobots\n\nCopyright 1994,1996\nTom Poindexter\ntpoindex@nyx.net\n\nVersion 2.0\nFebruary, 1996\n" "-image iconfn" 0 dismiss

}


###############################################################################
#
# set up main window
#
#

proc main_win {} {

#  global execCmd numList parms

  # define our icon 

  set tr_icon {
#define tr_width 48
#define tr_height 48
static char tr_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00, 0x70, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe1, 0x00, 0x00, 0x00,
   0x00, 0x00, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0xe1, 0x07, 0x00, 0x00,
   0x00, 0x00, 0xe0, 0x06, 0x00, 0x00, 0x00, 0x00, 0x70, 0x06, 0x00, 0x00,
   0x00, 0x00, 0x38, 0x06, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x06, 0x00, 0x00,
   0x00, 0x00, 0x0f, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00,
   0x00, 0x00, 0xfe, 0xff, 0x01, 0x00, 0x00, 0x00, 0xff, 0xff, 0x03, 0x00,
   0x80, 0x87, 0x03, 0x00, 0x07, 0x00, 0x80, 0xbf, 0x01, 0x50, 0x06, 0x00,
   0x00, 0xfc, 0x0f, 0x00, 0x06, 0x00, 0x00, 0xe0, 0x3f, 0x28, 0x06, 0x00,
   0x00, 0x80, 0x39, 0x00, 0x06, 0x00, 0x00, 0x80, 0x01, 0x14, 0x06, 0x00,
   0x00, 0x80, 0x0f, 0xc0, 0x07, 0x00, 0x00, 0x00, 0xff, 0xff, 0x03, 0x00,
   0x00, 0x00, 0xfc, 0xff, 0x00, 0x00, 0x00, 0xfc, 0xff, 0xff, 0x7f, 0x00,
   0x00, 0xfe, 0xff, 0xff, 0xff, 0x00, 0x00, 0x07, 0x00, 0x00, 0xc0, 0x01,
   0x00, 0x07, 0x00, 0x00, 0xc0, 0x01, 0x80, 0xff, 0xff, 0xff, 0xff, 0x03,
   0xc0, 0xff, 0xff, 0xff, 0xff, 0x07, 0xf0, 0x7f, 0x30, 0x0c, 0xfc, 0x1f,
   0xf0, 0x7d, 0x30, 0x0c, 0x7c, 0x1f, 0x38, 0xe0, 0x00, 0x00, 0x0e, 0x38,
   0x38, 0xe0, 0x00, 0x00, 0x0e, 0x38, 0x3c, 0xe2, 0x01, 0x00, 0x8f, 0x78,
   0x1c, 0xc7, 0x01, 0x00, 0xc7, 0x71, 0x3c, 0xe2, 0x01, 0x00, 0x8f, 0x78,
   0x38, 0xe0, 0x00, 0x00, 0x0e, 0x38, 0x38, 0xe0, 0x00, 0x00, 0x0e, 0x38,
   0xf0, 0x7d, 0x30, 0x0c, 0x7c, 0x1f, 0xf0, 0x7f, 0x30, 0x0c, 0xfc, 0x1f,
   0xc0, 0xff, 0xff, 0xff, 0xff, 0x07, 0x00, 0xff, 0xff, 0xff, 0xff, 0x01};
}

  image create bitmap iconfn -data $tr_icon -background ""

  set ::numList 0
  set ::execCmd start
  set me [winfo name .]

  option add *highlightThickness 0

  # make a toplevel icon window, iconwindow doesn't have transparent bg :-(
  catch {destroy .iconm}
  toplevel .iconm
  pack [label .iconm.i -image iconfn]

  wm title . "TclRobots"
  wm iconwindow . .iconm
  wm iconname . TclRobots
  wm protocol . WM_DELETE_WINDOW "catch {.f1.b5 invoke}"

  frame .f1
  button .f1.b1 -text "Run Battle" -width 12     -command {eval $::execCmd}
  button .f1.b2 -text "Simulator.."    -command sim
  button .f1.b3 -text "Tournament.."   -command tournament
  button .f1.b4 -text "About.."        -command about 
#  button .f1.b5 -text "Quit"           -command "clean_up; destroy ." 
  button .f1.b5 -text "Quit"           -command "destroy ."
  pack .f1.b1 .f1.b2 .f1.b3 .f1.b4 .f1.b5 -side left -expand 1 -fill both

  label .l -relief raised -text {Select robot files for battle}

  frame .f2 -width 520 -height 520 

  frame .f2.fl -relief sunken -borderwidth 3
  frame .f2.fr -relief sunken -borderwidth 3

  fileBox .f2.fl "Select" * "" [pwd] choose_file
  
  label .f2.fr.lab  -text "Robot files selected"
  listbox .f2.fr.l1 -relief sunken  -yscrollcommand ".f2.fr.s set" \
		-selectmode single
  scrollbar .f2.fr.s -command ".f2.fr.l1 yview"
  frame  .f2.fr.fb
  button .f2.fr.fb.b1 -text " Remove "     -command remove_file
  button .f2.fr.fb.b2 -text " Remove All " -command remove_all
  pack .f2.fr.fb.b1 .f2.fr.fb.b2 -side left -padx 5 -pady 5
  pack .f2.fr.lab -side top  -fill x
  pack .f2.fr.fb  -side bottom -fill x
  pack .f2.fr.s   -side right -fill y
  pack .f2.fr.l1  -side left  -expand 1 -fill both

  pack .f2.fl .f2.fr -side left -expand 1 -fill both -padx 10 -pady 10
  canvas .c -width 520 -height 520  -scrollregion "-10 -10 510 510"

  pack .f1 .l  -side top -fill both
  pack .f2 -side top -expand 1 -fill both

  wm geom . 524x574
  update
}

###############################################################################
#
# choose_file
#
proc choose_file {win filename} {
  set listsize $::numList
  .f2.fr.l1 insert end $filename
  incr ::numList
  set dir $filename
  for {set i 0} {$i <= $listsize} {incr i} {
    set d [.f2.fr.l1 get $i] 
    if {[string length $d] > [string length $dir]} {
      set dir  $d
    }
  }
  set idx [expr [string length [file dirname [file dirname $dir]] ]+1]
  .f2.fr.l1 xview $idx
}


###############################################################################
#
# choose_all
#
proc choose_all {} {
  set win .f2.fl
  set lsize [$win.l.lst size]
  for {set i 0} {$i < $lsize} {incr i} {
    set f [string trim [$win.l.lst get $i]]
    if ![string match */ $f] {
      choose_file $win $f
    }
  }
  
}

###############################################################################
#
# remove_file
#
proc remove_file {} {
  set idx -1
  catch {set idx [.f2.fr.l1 curselection]}
  if {$idx >= 0} {
    .f2.fr.l1 delete $idx
    incr  ::numList -1
  }
}


###############################################################################
#
# remove_all
#
proc remove_all {} {
  set idx $::numList
  if {$idx > 0} {
    .f2.fr.l1 delete 0 end
    set ::numList 0
  }
}

#######################################################################
# file selection box,  from my "wosql" in Oratcl
# modified not to use a toplevel
#######################################################################
# procs to support a file selection dialog box

########################
#
# fillLst
#
#    fill the fillBox listbox with selection entries
#

proc fillLst {win filt dir} {
  
  $win.l.lst delete 0 end

  cd $dir

  set dir [pwd]
  
  if {[string length $filt] == 0} {
    set filt *
  }
  set all_list [lsort [glob -nocomplain $dir/$filt]]

  set dlist  "$dir/../"
  set flist ""

  foreach f $all_list {
    if [file isfile $f] {
      lappend flist $f
    }
    if [file isdirectory $f] {
      lappend dlist ${f}/
    }
  }

  foreach d $dlist {
    $win.l.lst insert end $d
  }
  foreach f $flist {
    $win.l.lst insert end $f
  }

  $win.l.lst yview 0

  set idx [expr [string length [file dirname [file dirname $dir]] ]+1]

  $win.l.lst xview $idx
}


########################
#
# selInsert
#
#   insert into a selection entry, scroll to root name
#
proc selInsert {win pathname} {

  $win.sel delete 0 end
  $win.sel insert 0 $pathname
  set idx [expr [string length [file dirname [file dirname $pathname]] ]+1]
  $win.sel xview $idx
  $win.sel select from 0
}


########################
#
# fileOK
#
#   do the OK processing for fileBox
#

proc fileOK {win execproc} {
  
  # might not have a valid selection, so catch the selection
  # catch {  selInsert $win [lindex [selection get] 0] }
  catch {  selInsert $win [$win.l.lst get [$win.l.lst curselection]] }

  set f [lindex [$win.sel get] 0]
  if [file isdirectory $f] {
    #set f [file dirname $f]
    #set f [file dirname $f]
    cd $f
    set f [pwd]
    fillLst $win [$win.fil get] $f
  } else {
    # we don't know if a file is really there or not, let the execproc
    # figure it out.  also, window is passed if execproc wants to kill it.
    $execproc $win $f 
  }
}

########################
#
# fileBox
#
#   put up a file selection box
#    win - name of toplevel to use
#    filt - initial file selection filter 
#    initfile - initial file selection 
#    startdir - initial starting dir
#    execproc - proc to exec with selected file name
#
proc fileBox {win txt filt initfile startdir execproc} {

  if {[string length $startdir] == 0} {
    set startdir [pwd]
  }

  label $win.l1   -text "File Filter" -anchor w
  entry $win.fil  -relief sunken
  $win.fil insert 0 $filt
  label $win.l2   -text "Files" -anchor w
  frame $win.l  
  scrollbar $win.l.hor -orient horizontal -command "$win.l.lst xview" \
	    -relief sunken
  scrollbar $win.l.ver -orient vertical   -command "$win.l.lst yview" \
	    -relief sunken
  listbox $win.l.lst -yscroll "$win.l.ver set" -xscroll "$win.l.hor set" \
	    -selectmode single -relief sunken
  
  label $win.l3   -text "Selection" -anchor w
  scrollbar $win.scrl -orient horizontal -relief sunken \
                      -command "$win.sel xview"
  entry $win.sel  -relief sunken -xscroll "$win.scrl set"
  selInsert $win $initfile
  pack $win.l.ver -side right -fill y
  pack $win.l.hor -side bottom -fill x
  pack $win.l.lst -side left   -fill both  -expand 1 -ipadx 3

  frame $win.o  -relief sunken -border 1
  button $win.o.ok -text " $txt " -command "fileOK $win $execproc"
  button $win.all -text " Select All " -command "choose_all"
  button $win.filter -text " Filter " \
	  -command "fillLst $win \[$win.fil get\] \[pwd\]"

  pack $win.l1 -side top -fill x
  pack $win.fil -side top -pady 2 -fill x -ipadx 5
  pack $win.l2 -side top -fill x
  pack $win.l  -side top -fill both -expand 1
  pack $win.l3 -side top -fill x
  pack $win.sel -side top -pady 5 -fill x -ipadx 5
  pack $win.scrl -side top -fill x
  pack $win.o.ok -side left  -padx 5 -pady 5
  pack $win.o $win.all $win.filter  -side left -padx 5 -pady 10

  bind $win.fil <KeyPress-Return> "$win.filter invoke"
  bind $win.sel <KeyPress-Return> "$win.o.ok   invoke"
  bind $win.l.lst <ButtonRelease-1> \
   "+selInsert $win \[%W get \[ %W nearest %y \] \] "
  bind $win.l.lst <Double-1> \
   "selInsert $win \[%W get \[%W curselection\]\];  $win.o.ok invoke"
  bind $win <1> "$win.o.ok config -relief sunken"


  fillLst $win $filt $startdir
  selection own $win
  focus $win.sel

}

#
# end of the file selection box stuff
###########################################################################

###############################################################################
#
# update canvas with position of missiles and robots
#
#

proc show_robots {} {
    #  global c_tab s_tab parms
    set i 0
    foreach robot $::robots {
        # check robots
        if {$::data($robot,status)} {
            .c delete r$::data($robot,num)
            set x [expr $::data($robot,x)/$::scale]
            set y [expr (1000-$::data($robot,y))/$::scale]
            set arrow [lindex $::parms(shapes) $i]
            .c create line $x $y \
                [expr $x+($::c_tab($::data($robot,hdg))*5)] \
                [expr $y-($::s_tab($::data($robot,hdg))*5)] \
                -fill $::data($robot,color) \
                -arrow last -arrowshape $arrow -tags r$::data($robot,num)
        }
        # check missiles
        if {$::data($robot,mstate)} {
            .c delete m$::data($robot,num)
            set x [expr $::data($robot,mx)/$::scale]
            set y [expr (1000-$::data($robot,my))/$::scale]
            .c create oval [expr $x-2] [expr $y-2] [expr $x+2] [expr $y+2] \
                -fill black -tags m$::data($robot,num)
        }
        incr i
    }
    #delete all previous scans
    .c delete scan
    update
}



###############################################################################
#
# show scanner from a robot
#
#

proc show_scan {} {
    foreach robot $::robots {
        if {[.c find withtag s$::data($robot,name)] != ""} {
            return
        } elseif {$::data($robot,status)} {
            if {($::tick > 0) &&
                ([lindex $::data($robot,syscall,$::tick) 0] eq "scanner") && \
                ($::data($robot,syscall,$::tick) eq \
                     $::data($robot,syscall,[- $::tick 1]))} {

                set deg [lindex $::data($robot,syscall,$::tick) 1]
                set res [lindex $::data($robot,syscall,$::tick) 2]
                puts "deg: $deg, res: $res"

                set x [expr $::data($robot,x)/2]
                set y [expr (1000-$::data($robot,y))/2]
                .c create arc [expr $x-350] [expr $y-350] [expr $x+350] [expr $y+350] \
                    -start [expr $deg-$res] -extent [expr 2*$res + 1] \
                    -fill "" -outline $::data($robot,color) -stipple gray50 -width 1 -tags "scan s$::data($robot,num) "
                
                update
            }
        }
    }
}

###############################################################################
#
# show explosion of missile
#
#

proc show_explode {robot} {
    .c delete m$::data($robot,num)
    set x [expr $::data($robot,mx)/2]
    set y [expr (1000-$::data($robot,my))/2]

    .c create oval [expr $x-10] [expr $y-10] [expr $x+10] [expr $y+10] \
        -outline yellow -fill yellow  -width 1 \
        -tags e$::data($robot,num)
    .c create oval [expr $x-5] [expr $y-5] [expr $x+5] [expr $y+5] \
        -outline orange -fill orange  -width 1  \
        -tags e$::data($robot,num)
    .c create oval [expr $x-3] [expr $y-3] [expr $x+3] [expr $y+3] \
        -outline red    -fill red     -width 1  \
        -tags e$::data($robot,num)

    update
    after 100 ".c delete e$::data($robot,num)"
}

###############################################################################
#
# draw arena boundry
#
#

proc draw_arena {} {
    set side [/ 1000 $::scale]
    .c create line 0     0     0     $side
    .c create line 0     0     $side 0
    .c create line $side 0     $side $side
    .c create line 0     $side $side $side
}

###############################################################################
#
# start a match
#
#

proc start {} {
#  global rob1 rob2 rob3 rob4 parms running halted ticks ::execCmd ::numList
#  global finish outfile tourn_type nowin

  set finish ""
  set players "battle: "
  set ::running 0
  set halted  0
  set ticks   0
  set quads $::parms(quads)
  set colors $::parms(colors)
  set numbots 2

  .l configure -text "Initializing..."

  # clean up robots
#  foreach robot $::robots {
#      set r(status) 0
#      set r(mstate) 0
#      set r(name)   ""
#      set r(pid)    -1
#  }

  # get robot filenames from window
  set ::robots ""
  set lst .f2.fr.l1
  for {set i 0} {$i < $::numList && $i<=4} {incr i} {
      # Give the robots names like r0, r1, etc.
      set robot r[+ $i 1]
      # Update list of robots
      lappend ::robots $robot
      # Read 
      set f [open [$lst get $i]]
      set ::data($robot,code) [read $f]
      close $f
  }

#  if {[llength $robots] < 2} {
#    .l configure -text "Must have at least two robots to run a battle"
#    return
#  }

  set dot_geom [winfo geom .]
  set dot_geom [split $dot_geom +]
  set dot_x [lindex $dot_geom 1]
  set dot_y [lindex $dot_geom 2]

  # pick random starting quadrant, colors and init robots
  set i 1
  foreach robot $::robots {
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
    set winy [expr (($i-1)*145)]

      init

      set ::data($robot,color) $color

#    set rc [robot_init rob$i $f $x $y $winx $winy $color]

#    if {$rc == 0} {
#      oops rob$i
#      clean_up
#      return
#    }

#    upvar #0 rob$i r
#    append players "$r(name) " 

    incr i
#    incr numbots -1
  }

  pack forget .f2
  pack .c -side top -expand 1 -fill both
  draw_arena

  # start robots
  .l configure -text "Running"
  set ::execCmd halt
  .f1.b1 configure -state normal    -text "Halt"
  .f1.b2 configure -state disabled
  .f1.b3 configure -state disabled
  .f1.b4 configure -state disabled
  .f1.b5 configure -state disabled
#  start_robots


  # start physics package
#  show_robots
  set ::running 1
#  every $parms(tick) update_robots {$running}
#  tkwait variable running

      main

  vwait running

  # find winnner
  if {$halted} {
      .l configure -text "Battle halted"
  } else {
      set alive 0
      set winner ""
      set num_team 0
      set diffteam ""
      set win_color black
      foreach robot $::robots {
          if {$::data($robot,status)} {
              #disable_robot $robot 0
              incr alive
              lappend winner $::data($robot,name)
              set win_color $::data($robot,color)
              if {$::data($robot,team) != ""} {
                  if {[lsearch -exact $diffteam $::data($robot,team)] == -1} {
                      lappend diffteam $::data($robot,team)
                      incr num_team
                  }
              } else {
                  incr num_team
              }
          }
      }

      switch $alive {
          0 {
              set msg "No robots left alive"
              .l configure -text $msg
          }
          1 {
              if {[string length $diffteam] > 0} {
                  set diffteam "Team $diffteam"
              }
              set msg "Winner!\n\n$diffteam\n$winner"
              .l configure -text "$winner wins!" -fg $win_color
          }
          default {
              # check for teams
              if {$num_team == 1} {
                  set msg "Winner!\n\nTeam $diffteam\n$winner"
                  .l configure -text "Team: $diffteam : $winner wins!"
              } else {
                  set msg "Tie:\n\n$winner"
                  .l configure -text "Tie: $winner"
              }
          }
      }
      if {$::nowin} {
          set msg2 [join [split $msg \n] " "]
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
          catch {write_file $outfile "$players\n$finish\n$msg2\n\n$score\n\n\n"}
      } else {
          tk_dialog2 .winner "Results" $msg "-image iconfn" 0 dismiss
      }
  }

  #  set ::execCmd "kill_wishes \"$robots\""
  .f1.b1 configure -state normal -text "Reset"

}

# standard tk_dialog modified to use -image on label

proc tk_dialog2 {w title text bitmap default args} {
#    global nowin
#    global tkPriv

    if {$::nowin} return

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    catch {destroy $w}
    toplevel $w -class Dialog
    wm title $w $title
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW { }
    wm transient $w [winfo toplevel [winfo parent $w]]
    frame $w.top -relief raised -bd 1
    pack $w.top -side top -fill both
    frame $w.bot -relief raised -bd 1
    pack $w.bot -side bottom -fill both

    # 2. Fill the top part with bitmap and message.

    label $w.msg -wraplength 3i -justify left -text $text  
    pack $w.msg -in $w.top -side right -expand 1 -fill both -padx 3m -pady 3m
    if {$bitmap != ""} {
        if {[llength $bitmap] > 1} { 
          switch -- [lindex $bitmap 0] {
	    -image {set type -image; set bitmap [lindex $bitmap 1]}
	    -bitmap {set type -bitmap; set bitmap [lindex $bitmap 1]}
	    default {set type -bitmap; set bitmap [lindex $bitmap 1]}
	  }
        } else {
          set type -bitmap
        }
	label $w.bitmap $type $bitmap
	pack $w.bitmap -in $w.top -side left -padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach but $args {
	button $w.button$i -text $but -command "set ::tkPriv(button) $i"
	if {$i == $default} {
	    frame $w.default -relief sunken -bd 1
	    raise $w.button$i $w.default
	    pack $w.default -in $w.bot -side left -expand 1 -padx 3m -pady 2m
	    pack $w.button$i -in $w.default -padx 2m -pady 2m
	    bind $w <Return> "$w.button$i flash; set tkPriv(button) $i"
	} else {
	    pack $w.button$i -in $w.bot -side left -expand 1  -padx 3m -pady 2m
	}
	incr i
    }

    # 4. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw $w
    update idletasks
    set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2  - [winfo vrootx [winfo parent $w]]]
    set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2  - [winfo vrooty [winfo parent $w]]]
    wm geom $w +$x+$y
    wm deiconify $w

    # 5. Set a grab and claim the focus too.

    set oldFocus [focus]
    set oldGrab [grab current $w]
    if {$oldGrab != ""} {
	set grabStatus [grab status $oldGrab]
    }
    grab $w
    tkwait visibility $w
    if {$default >= 0} {
	focus $w.button$default
    } else {
	focus $w
    }

    # 6. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    tkwait variable ::tkPriv(button)
    catch {focus $oldFocus}
    destroy $w
    if {$oldGrab != ""} {
	if {$grabStatus == "global"} {
	    grab -global $oldGrab
	} else {
	    grab $oldGrab
	}
    }
    return $::tkPriv(button)
}

###############################################################################
#
# halt a running match
#
#

proc halt {} {
#    global execCmd halted running
    set ::running 0
    .l configure -text "Stopping battle, standby"
    update
    foreach robot $::robots {
        if {$::data($robot,status)} {
            #disable_robot $robot 0
        }
    }
    set ::halted 1
    set ::execCmd reset
    .f1.b1 configure -state normal -text "Reset"
    .f1.b2 configure -state disabled
    .f1.b3 configure -state disabled
    .f1.b4 configure -state disabled
    .f1.b5 configure -state disabled
}


###############################################################################
#
# reset to file select state
#
#

proc reset {} {
  global execCmd
  .c delete all
  set execCmd start
  .f1.b1 configure -text "Run Battle" 
  pack forget .c
  pack .f2 -side top -expand 1 -fill both
  .l configure -text "Select robot files for battle" -fg black
  .f1.b1 configure -state normal
  .f1.b2 configure -state normal
  .f1.b3 configure -state normal
  .f1.b4 configure -state normal
  .f1.b5 configure -state normal
}
