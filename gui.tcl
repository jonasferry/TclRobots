package require Tk

###############################################################################
#
# about box
#
#

proc about {} {
    tk_dialog2 .about "About TclRobots" "TclRobots\n\nCopyright 2010\nJonas Ferry\njonas@tclrobots.org\n\nVersion 3.0\nFebruary, 2010\n" "-image iconfn" 0 dismiss

}

###############################################################################
#
# choose_file
#
proc choose_file {win filename} {
    set listsize $::numlist
    $::robotlist_lb insert end $filename
    incr ::numlist
    set dir $filename
    for {set i 0} {$i <= $listsize} {incr i} {
        set d [$::robotlist_lb get $i]
        if {[string length $d] > [string length $dir]} {
            set dir  $d
        }
    }
    set index [expr [string length [file dirname [file dirname $dir]] ]+1]
    $::robotlist_lb xview $index
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
    set index -1
    catch {set index [.f2.fr.f.lb curselection]}
    if {$index >= 0} {
        .f2.fr.f.lb delete $index
        incr  ::numlist -1
    }
}


###############################################################################
#
# remove_all
#
proc remove_all {} {
    set index $::numlist
    if {$index > 0} {
        $::robotlist_lb delete 0 end
        set ::numlist 0
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

    set index [expr [string length [file dirname [file dirname $dir]] ]+1]

    $win.l.lst xview $index
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
    set index [expr [string length [file dirname [file dirname $pathname]] ]+1]
    $win.sel xview $index
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
# clean up all left overs
#
#

proc clean_up {} {
    .l configure -text "Standby, cleaning up any left overs...."
    update

    foreach robot $::activeRobots {
        disable_robot $robot
    }
}

###############################################################################
#
# update canvas and find current width
#
#

proc show_arena {} {
    set w [winfo width  $::arena_c]
    set h [winfo height $::arena_c]

    set ::scale [/ 1 [/ 1000.0 $h]]
    set ::border 10
    set ::side [- [int [* 1000 $::scale]] [* 2 $::border]]

    incr ::hej
    if {$::hej > 0} {
        puts "scale $::scale"
        puts "side $::side"
        #exit
    }

    set b  $::border
    set sb [+ $::side $::border]
    $::arena_c configure -scrollregion "-$b -$b $sb $sb"

    $::arena_c delete wall

    $::arena_c create line 0       0       0       $::side -tags wall
    $::arena_c create line 0       0       $::side 0       -tags wall
    $::arena_c create line $::side 0       $::side $::side -tags wall
    $::arena_c create line 0       $::side $::side $::side -tags wall
}

proc border_check {coord} {
    if {$coord < $::border} {
        return $::border
    } elseif {$coord > $::side} {
        return $::side
    } else {
        return $coord
    }
}

###############################################################################
#
# update canvas with position of missiles and robots
#
#

proc show_robots {} {
    set i 0
    foreach robot $::allRobots {
        # check robots
        if {$::data($robot,status)} {
            $::arena_c delete r$::data($robot,num)
            set x [border_check [* $::data($robot,x) $::scale]]
            set y [border_check [* [- 1000 $::data($robot,y)] $::scale]]
            puts "loc $robot $x ($::data($robot,x)) $y ($::data($robot,y))"
            set arrow [lindex $::parms(shapes) [% $i 4]]
            $::arena_c create line $x $y \
                [expr $x+($::c_tab($::data($robot,hdg))*5)] \
                [expr $y-($::s_tab($::data($robot,hdg))*5)] \
                -fill $::data($robot,color) \
                -arrow last -arrowshape $arrow -tags r$::data($robot,num)
        }
        # check missiles
        if {$::data($robot,mstate)} {
            $::arena_c delete m$::data($robot,num)
            set x [border_check [* $::data($robot,mx) $::scale]]
            set y [border_check [* [- 1000 $::data($robot,my)] $::scale]]
            $::arena_c create oval \
                [expr $x-2] [expr $y-2] [expr $x+2] [expr $y+2] \
                -fill black -tags m$::data($robot,num)
        }
        incr i
    }
    #delete all previous scans
    $::arena_c delete scan
    update
}



###############################################################################
#
# show scanner from a robot
#
#

proc show_scan {} {
    foreach robot $::activeRobots {
        if {[$::arena_c find withtag s$::data($robot,name)] != ""} {
            return
        } elseif {$::data($robot,status)} {
            if {([lindex $::data($robot,syscall,$::tick) 0] eq "scanner") && \
                    ($::data($robot,syscall,$::tick) eq \
                         $::data($robot,syscall,[- $::tick 1]))} {

                set deg [lindex $::data($robot,syscall,$::tick) 1]
                set res [lindex $::data($robot,syscall,$::tick) 2]
                #puts "deg: $deg, res: $res"

                set x [border_check [* $::data($robot,x) $::scale]]
                set y [border_check [* [- 1000 $::data($robot,y)] $::scale]]
                puts "scan $robot $x $y"
                set val [* [* 350 $::scale] 2]
                $::arena_c create arc \
                    [- $x $val] [- $y $val] \
                    [+ $x $val] [+ $y $val] \
                    -start [expr $deg-$res] \
                    -extent [expr 2*$res + 1] -fill "" \
                    -outline $::data($robot,color) -stipple gray50 -width 1 \
                    -tags "scan s$::data($robot,num) "

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
    $::arena_c delete m$::data($robot,num)
    set x [* $::data($robot,mx) $::scale]
    set y [* [- 1000 $::data($robot,my)] $::scale]

    set val [* 20 $::scale]
    $::arena_c create oval [- $x $val] [- $y $val] [+ $x $val] [+ $y $val] \
        -outline yellow -fill yellow  -width 1 \
        -tags e$::data($robot,num)

    set val [* 10 $::scale]
    $::arena_c create oval [- $x $val] [- $y $val] [+ $x $val] [+ $y $val] \
        -outline orange -fill orange  -width 1  \
        -tags e$::data($robot,num)

    set val [* 6 $::scale]
    $::arena_c create oval [- $x $val] [- $y $val] [+ $x $val] [+ $y $val] \
        -outline red    -fill red     -width 1  \
        -tags e$::data($robot,num)

    update
    after 100 "$::arena_c delete e$::data($robot,num)"
}

proc show_health {} {
    set ::robotHealth {}
    set index 0
    foreach robot $::allRobots {
        lappend ::robotHealth "$robot $::data($robot,health)"
        $::robotHealth_lb itemconfigure $index -foreground $::data($robot,color)
        incr index
    }
}

#
# Returns a list of colors
#
proc distinct_colors {n} {
    set nn 1
    set hue_increment .15
    set s 1.0 ;# non-variable saturation

    set lum_steps [expr $n * $hue_increment]
    set int_lum_steps [expr int($lum_steps)]
    if {$lum_steps > $int_lum_steps} { ;# round up
        set lum_steps [expr $int_lum_steps + 1]
    }
    set lum_increment [expr .7 / $lum_steps]

    for {set l 1.0} {$l > 0.4} {set l [expr {$l - $lum_increment}]} {
        for {set h 0.0} {$h < 1.0} {set h [expr {$h + $hue_increment}]} {
            lappend rc [hls2tk $h $l $s]
            incr nn
            if {$nn > $n} { return $rc }
        }
    }
    return $rc
}

proc hls2tk {h l s} {
    set rgb [hls2rgb $h $l $s]
    foreach c $rgb {
        set intc [expr {int($c * 256)}]
        if {$intc == 256} { set intc 255 }
        set c1 [format %1X $intc]
        if {[string length $c1] == 1} {set c1 "0$c1"}
        append init $c1
    }
    return #$init
}

proc hls2rgb {h l s} {
    # h, l and s are floats between 0.0 and 1.0, ditto for r, g and b
    # h = 0   => red
    # h = 1/3 => green
    # h = 2/3 => blue

    set h6 [expr {($h-floor($h))*6}]
    set r [expr {  $h6 <= 3 ? 2-$h6
                            : $h6-4}]
    set g [expr {  $h6 <= 2 ? $h6
                            : $h6 <= 5 ? 4-$h6
                            : $h6-6}]
    set b [expr {  $h6 <= 1 ? -$h6
                            : $h6 <= 4 ? $h6-2
                            : 6-$h6}]
    set r [expr {$r < 0.0 ? 0.0 : $r > 1.0 ? 1.0 : double($r)}]
    set g [expr {$g < 0.0 ? 0.0 : $g > 1.0 ? 1.0 : double($g)}]
    set b [expr {$b < 0.0 ? 0.0 : $b > 1.0 ? 1.0 : double($b)}]

    set r [expr {(($r-1)*$s+1)*$l}]
    set g [expr {(($g-1)*$s+1)*$l}]
    set b [expr {(($b-1)*$s+1)*$l}]
    return [list $r $g $b]
}

###############################################################################
#
# start a match
#
#

proc init_arena {} {
    set ::mode "arena"
    set finish ""
    set players "battle: "
    set ::running 0
    set halted  0
    set quads $::parms(quads)

    $::info_l configure -text "Initializing..."

    # get robot filenames from window
    set lst $::robotlist_lb
    set ::robotFiles {}

    for {set i 0} {$i < $::numlist} {incr i} {
        lappend ::robotFiles [$lst get $i]
    }

    grid forget $::sel_f
    grid $::game_f -column 0 -row 2 -sticky nsew
    show_arena

    # start robots
    $::info_l configure -text "Running"
    set ::execCmd halt
    $::run_b   configure -state normal    -text "Halt"
    $::sim_b   configure -state disabled
    $::tourn_b configure -state disabled
    $::about_b configure -state disabled
    $::quit_b  configure -state disabled

    set ::colors [distinct_colors [llength $::robotFiles]]

    #  start_robots
    main

    # find winnner
    if {$halted} {
        .l configure -text "Battle halted"
    } else {
        tk_dialog2 .winner "Results" $::win_msg "-image iconfn" 0 dismiss
    }

    #  set ::execCmd "kill_wishes \"$robots\""
    $::run_b configure -state normal -text "Reset"

}

# standard tk_dialog modified to use -image on label

proc tk_dialog2 {w title text bitmap default args} {
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
    set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2  - \
               [winfo vrootx [winfo parent $w]]]
    set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2  - \
               [winfo vrooty [winfo parent $w]]]
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
    $::info_l configure -text "Stopping battle, standby"
    update
    foreach robot $::allRobots {
        if {$::data($robot,status)} {
            #disable_robot $robot 0
        }
    }
    set ::halted 1
    set ::execCmd reset
    $::run_b   configure -state normal -text "Reset"
    $::sim_b   configure -state disabled
    $::tourn_b configure -state disabled
    $::about_b configure -state disabled
    $::quit_b  configure -state disabled
}


###############################################################################
#
# reset to file select state
#
#

proc reset {} {
    clean_up

    $::arena_c delete all
    set ::execCmd init_arena
    $::run_b configure -text "Run Battle"
    grid forget $::game_f
    grid $::sel_f -column 0 -row 2 -sticky nsew
    $::info_l configure -text "Select robot files for battle"
    $::run_b   configure -state normal
    $::sim_b   configure -state normal
    $::tourn_b configure -state normal
    $::about_b configure -state normal
    $::quit_b  configure -state normal
}


###############################################################################
#
# start the simulator
#
#

proc sim {} {
#  global rob1 rob2 rob3 rob4 parms running halted ticks execCmd
#  global step numList bgColor

    if {$::mode eq {}} {
        set ::mode "init_sim"
        set halted  0
        set ticks   0
        set color red
        .l configure -text "Simulator"

        # get robot filenames from window
        set lst $::robotlist_lb
        set ::robotFiles {}

        for {set i 0} {$i < $::numlist} {incr i} {
            lappend ::robotFiles [$lst get $i]
        }

        grid forget $::sel_f
        grid $::game_f -column 0 -row 2 -sticky nsew
        show_arena

        puts check

        # start robots
        .l configure -text "Running Simulator"
        set ::execCmd reset

        $::run_b   configure -state disabled
        $::sim_b   configure -state disabled
        $::tourn_b configure -state disabled
        $::about_b configure -state disabled
        $::quit_b  configure -state disabled

        #  start_robots
        puts check0
        set ::colors [distinct_colors [llength $::robotFiles]]
        main
        puts check1
    } elseif {$::mode eq "init_sim"} {
        set ::mode sim

        # setup target
        set robot target
        lappend ::allRobots target
        lappend ::activeRobots target

        set ::data($robot,name)    target_0
        set ::data($robot,status)  1
        set ::data($robot,num)     1
        set ::data($robot,color)   black
        set ::data($robot,x)       500
        set ::data($robot,y)       500
        set ::data($robot,health)  100
        set ::data($robot,speed)   0
        set ::data($robot,dspeed)  0
        set ::data($robot,hdg)     0
        set ::data($robot,dhdg)    0
        set ::data($robot,mstate)  0
        set ::data($robot,reload)  0
        set ::data($robot,hflag)   0
        set ::data($robot,heat)    0
        set ::data($robot,team)    "target"
        set ::data($robot,btemp)   0

        # start physics package
        #show_robots

    } elseif {$::mode eq "sim"} {
        set ::mode "arena"
        puts arena;exit
    } else {
        # make a toplevel icon window, iconwindow doesn't have transparent bg :-(
        catch {destroy .icons}
        toplevel .icons
        pack [label .icons.i -image iconfn]

        # create toplevel simulator debug window
        set step 1
        catch {destroy .debug}
        toplevel .debug
        wm title .debug "Simulator Probe"
        wm iconwindow .debug .icons
        wm iconname .debug "TclRobots Sim"
        wm group .debug .
        wm group . .debug
        wm protocol .debug WM_DELETE_WINDOW "catch {.debug.f1.end invoke}"
        incr i
        set winx [expr $dot_x+540]
        set winy [expr $dot_y+(($i-1)*145)]
        wm geom .debug +${winx}+$winy
        frame .debug.f1 -relief raised -borderwidth 2
        checkbutton .debug.f1.cb -text "Step syscalls" -variable step -anchor w \
            -command do_step -relief raised
        button .debug.f1.step -text "Single Step" -command do_single
        button .debug.f1.damage -text "5% Hit"    -command "incr rob1(damage) 5"
        button .debug.f1.ping   -text "Scan"      -command "set rob1(ping) 1"
        button .debug.f1.end -text "Close" \
            -command "trace vdelete rob1(hflag) w set_h_bg
	               set ::data($robot,status) 0; clean_up; reset; destroy .debug"
        pack .debug.f1.cb .debug.f1.step .debug.f1.damage .debug.f1.ping \
            .debug.f1.end  -side left -pady 5 -padx 3

        frame .debug.f2 -relief raised -borderwidth 2
        label .debug.f2.l1 -text "X:" -anchor e -width 8
        entry .debug.f2.x -width 7 -textvariable rob1(x)  -relief sunken
        label .debug.f2.l2 -text "Y:"  -anchor e -width 8
        entry .debug.f2.y -width 7 -textvariable rob1(y)  -relief sunken
        label .debug.f2.l3 -text "Heat:"  -anchor e -width 8
        entry .debug.f2.h -width 7 -textvariable rob1(heat)  -relief sunken
        pack .debug.f2.l1 .debug.f2.x  .debug.f2.l2 .debug.f2.y \
            .debug.f2.l3 .debug.f2.h -side left -pady 5 -padx 1

        set bgColor [.debug.f2.h cget -bg]
        bind  .debug.f2.x <Return> {ver_range rob1(x) 0 999; \
                                        set rob1(orgx) $rob1(x) ;set rob1(range) 0}
        bind  .debug.f2.x <Leave>  {ver_range rob1(x) 0 999; \
                                        set rob1(orgx) $rob1(x) ;set rob1(range) 0}
        bind  .debug.f2.y <Return> {ver_range rob1(y) 0 999; \
                                        set rob1(orgy) $rob1(y) ;set rob1(range) 0}
        bind  .debug.f2.y <Leave>  {ver_range rob1(y) 0 999; \
                                        set rob1(orgy) $rob1(y) ;set rob1(range) 0}
        bind  .debug.f2.h <Return> {ver_range rob1(heat) 0 200}
        bind  .debug.f2.h <Leave>  {ver_range rob1(heat) 0 200}
        trace variable rob1(hflag) w set_h_bg

        frame .debug.fb -relief raised -borderwidth 2
        label .debug.fb.l4 -text "Speed:" -anchor e -width 8
        entry .debug.fb.s -width 7 -textvariable rob1(speed) -relief sunken
        label .debug.fb.l5 -text "Heading:" -anchor e -width 8
        entry .debug.fb.h -width 7 -textvariable rob1(hdg) -relief sunken
        label .debug.fb.l6 -text "Damage:" -anchor e -width 8
        entry .debug.fb.d -width 7 -textvariable rob1(damage) -relief sunken
        pack .debug.fb.l4 .debug.fb.s  .debug.fb.l5 .debug.fb.h \
            .debug.fb.l6 .debug.fb.d  -side left -pady 5 -padx 1
        bind  .debug.fb.s <Return> {ver_range rob1(speed) 0 100; \
                                        set rob1(dspeed) $rob1(speed)}
        bind  .debug.fb.s <Leave>  {ver_range rob1(speed) 0 100; \
                                        set rob1(dspeed) $rob1(speed)}
        bind  .debug.fb.h <Return> {ver_range rob1(hdg) 0 359; \
                                        set rob1(dhdg) $rob1(hdg) ;set rob1(range) 0; \
                                        set rob1(orgx) $rob1(x); set rob1(orgy) $rob1(y)}
        bind  .debug.fb.h <Leave> {ver_range rob1(hdg) 0 359; \
                                       set rob1(dhdg) $rob1(hdg) ;set rob1(range) 0; \
                                       set rob1(orgx) $rob1(x); set rob1(orgy) $rob1(y)}
        bind  .debug.fb.d <Return> {ver_range rob1(damage) 0 100}
        bind  .debug.fb.d <Leave>  {ver_range rob1(damage) 0 100}

        frame .debug.f3 -relief raised -borderwidth 2
        label .debug.f3.l1 -text "Last syscall: " -anchor e
        label .debug.f3.s -width 20 -textvariable rob1(syscall) -anchor w
        label .debug.f3.l3 -text "Tick:" -anchor e -width 6
        label .debug.f3.t -width 5 -textvariable ticks -anchor w -width 5
        label .debug.f3.l4 -text "Barrel:" -anchor e -width 6
        label .debug.f3.b -width 5 -textvariable rob1(btemp) -anchor w -width 5
        pack .debug.f3.l1 .debug.f3.s .debug.f3.l3 .debug.f3.t  \
            .debug.f3.l4 .debug.f3.b  -side left -pady 5 -padx 2

        frame .debug.f4 -relief raised -borderwidth 2
        label .debug.f4.l1 -text "Variable: " -anchor e
        entry .debug.f4.var -width 10 -relief sunken
        label .debug.f4.l2 -text "Value: " -anchor e
        entry .debug.f4.val -width 10 -relief sunken
        button .debug.f4.examine -text " Examine " -command examine
        button .debug.f4.set     -text " Set "     -command setval
        pack .debug.f4.l1 .debug.f4.var .debug.f4.l2 .debug.f4.val \
            .debug.f4.examine .debug.f4.set -side left -pady 5 -padx 2
        bind .debug.f4.var <Key-Return> ".debug.f4.examine invoke"
        bind .debug.f4.val <Key-Return> ".debug.f4.set     invoke"

        pack .debug.f1 .debug.f2 .debug.fb .debug.f3 .debug.f4 -side top -fill x

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
        do_step
    }
}


# define our battle tank icon used in the About popup
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

image create bitmap iconfn -data $::tr_icon -background ""

proc init_gui {} {
    # Create and grid the outer content frame
    # The button row
    grid columnconfigure . 0 -weight 1
    # The content frames sel and game
    grid rowconfigure    . 2 -weight 1

    set ::execCmd init_arena
    set ::mode {}

    # Create button frame and buttons
    set ::buttons_f [ttk::frame .f1]
    set ::run_b     [ttk::button .f1.b0 -text "Run Battle" \
                         -command {eval $::execCmd}]
    set ::sim_b     [ttk::button .f1.b1 -text "Simulator" \
                         -command sim]
    set ::tourn_b   [ttk::button .f1.b2 -text "Tournament" \
                         -command tournament]
    set ::about_b   [ttk::button .f1.b3 -text "About" -command about]
    set ::quit_b    [ttk::button .f1.b4 -text "Quit" \
                         -command "destroy ."]

    # Grid button frame and buttons
    grid $::buttons_f -column 0 -row 0 -sticky nsew
    grid $::run_b     -column 0 -row 0 -sticky nsew
    grid $::sim_b     -column 1 -row 0 -sticky nsew
    grid $::tourn_b   -column 2 -row 0 -sticky nsew
    grid $::about_b   -column 3 -row 0 -sticky nsew
    grid $::quit_b    -column 4 -row 0 -sticky nsew

    grid columnconfigure $::buttons_f all -weight 1

    # make a toplevel icon window, iconwindow doesn't have transparent bg
    catch {destroy .iconm}
    toplevel .iconm
    grid [label .iconm.i -image iconfn]

    wm title . "TclRobots"
    wm iconwindow . .iconm
    wm iconname . TclRobots
    wm protocol . WM_DELETE_WINDOW "catch {$::quit_b invoke}"

    # The info label
    set ::info_l [ttk::label .l -relief solid \
                      -text "Select robot files for battle"]

    # The contents frame contains two frames
    set ::sel_f [ttk::frame .f2 -width 520 -height 520]

    # Contents left frame
    set sel0_f [ttk::frame $::sel_f.fl -relief sunken -borderwidth 3]

    # Contents right frame
    set sel1_f [ttk::frame $::sel_f.fr -relief sunken -borderwidth 3]

    # The file selection box
    set files_fb [fileBox $::sel_f.fl "Select" * "" [pwd] choose_file]

    # The robot list info label
    set robotlist_l  [ttk::label $::sel_f.fr.l -text "Robot files selected"]

    # A frame with the robot list and a scrollbar
    set robotlist_f  [ttk::frame $::sel_f.fr.f]

    # The robot list
    set ::robotlist_lb [listbox $::sel_f.fr.f.lb -relief sunken  \
                            -yscrollcommand "$::sel_f.fr.f.s set" \
                            -selectmode single]

    # The scrollbar
    set ::robotlist_s  [ttk::scrollbar $::sel_f.fr.f.s \
                            -command "$::robotlist_lb yview"]

    # A frame with the two remove buttons
    set remove_f     [ttk::frame  $::sel_f.fr.r]

    # Remove single file
    set remove_b     [ttk::button $::sel_f.fr.r.b1 -text " Remove " \
                          -command remove_file]

    # Remove all files
    set removeall_b  [ttk::button $::sel_f.fr.r.b2 -text " Remove All " \
                          -command remove_all]

    grid $::info_l       -column 0 -row 1 -sticky nsew
    grid $::sel_f        -column 0 -row 2 -sticky nsew
    grid $sel0_f         -column 0 -row 0 -sticky nsew
    grid $sel1_f         -column 1 -row 0 -sticky nsew

    grid $robotlist_l    -column 0 -row 0 -sticky nsew
    grid $robotlist_f    -column 0 -row 1 -sticky nsew
    grid $::robotlist_lb -column 0 -row 0 -sticky nsew
    grid $::robotlist_s  -column 1 -row 0 -sticky nsew
    grid $remove_f       -column 0 -row 2 -sticky nsew
    grid $remove_b       -column 0 -row 0 -sticky nsew
    grid $removeall_b    -column 1 -row 0 -sticky nsew

    grid rowconfigure $::sel_f       0 -weight 1
    grid columnconfigure $::sel_f    0 -weight 1
    grid rowconfigure $sel1_f        1 -weight 1
    grid rowconfigure $robotlist_f all -weight 1

    # The contents frame contains two frames
    set ::game_f [ttk::frame .f3 -width 520 -height 520]

    # The battle field canvas
    set ::arena_c [canvas $::game_f.c -background white]
    bind $::arena_c <Configure> {show_arena}

    # The robot health list
    set ::robotHealth {}
    set ::robotHealth_lb [listbox $::game_f.h -listvariable ::robotHealth]

    grid $::arena_c        -column 0 -row 0 -sticky nsew
    grid $::robotHealth_lb -column 1 -row 0 -sticky nsew
    grid columnconfigure $::game_f 0 -weight 1
    grid rowconfigure    $::game_f 0 -weight 1
}

proc gui {} {
    if {$::mode eq "arena"} {
        show_robots
        show_scan
        show_health
    } elseif {[eq $::mode "init_sim"] || \
                  [eq $::mode "sim"]} {
        puts "gui: $::mode"
       sim
    } else {
        puts "Mode Error";exit
    }
}