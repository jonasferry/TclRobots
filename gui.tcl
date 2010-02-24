package require Tk

###############################################################################
#
# about box
#
#

proc about {} {
    tk_dialog2 .about "About TclRobots" "TclRobots\n\nCopyright 2010\nJonas Ferry\njonas.ferry@gmail.com\n\nDevelopment Version\nFebruary, 2010\n" "-image iconfn" 0 dismiss

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
    set index [+ [string length [file dirname [file dirname $dir]]] 1]
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
        if {![string match */ $f]} {
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
    set all_list [lsort -dictionary [glob -nocomplain $dir/$filt]]

    set dlist [list "$dir/../"]
    set flist ""

    foreach f $all_list {
        if {[file isfile $f]} {
            lappend flist $f
        }
        if {[file isdirectory $f]} {
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

    set index [+ [string length [file dirname [file dirname $dir]]] 1]

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
    set index [+ [string length [file dirname [file dirname $pathname]]] 1]
    #set index [$win.sel index end]
    $win.sel xview $index
    after idle $win.sel xview $index
    #$win.sel select range 0 0
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
    if {[file isdirectory $f]} {
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

    ttk::label $win.l1   -text "File Filter" -anchor w
    ttk::entry $win.fil
    $win.fil insert 0 $filt
    ttk::label $win.l2   -text "Files" -anchor w
    ttk::frame $win.l
    ttk::scrollbar $win.l.hor -orient horizontal -command "$win.l.lst xview"
    ttk::scrollbar $win.l.ver -orient vertical   -command "$win.l.lst yview"
    listbox $win.l.lst -yscroll "$win.l.ver set" -xscroll "$win.l.hor set" \
	    -selectmode single -relief sunken

    ttk::label $win.l3   -text "Selection" -anchor w
    ttk::scrollbar $win.scrl -orient horizontal \
        -command "$win.sel xview"
    ttk::entry $win.sel -xscroll "$win.scrl set"
    selInsert $win $initfile
    grid $win.l.lst $win.l.ver -sticky news
    grid $win.l.hor            -sticky we
    grid columnconfigure $win.l $win.l.lst -weight 1
    grid rowconfigure    $win.l $win.l.lst -weight 1

    ttk::button $win.ok -text " $txt " -command "fileOK $win $execproc" \
            -default active
    ttk::button $win.all -text " Select All " -command "choose_all"
    ttk::button $win.filter -text " Filter " \
            -command "fillLst $win \[$win.fil get\] \[pwd\]"

    pack $win.l1 -side top -fill x
    pack $win.fil -side top -pady 2 -fill x -ipadx 5
    pack $win.l2 -side top -fill x
    pack $win.l  -side top -fill both -expand 1
    pack $win.l3 -side top -fill x
    pack $win.sel -side top -pady 5 -fill x -ipadx 5
    pack $win.scrl -side top -fill x
    pack $win.ok $win.all $win.filter  -side left -padx 5 -pady 10

    bind $win.fil <KeyPress-Return> "$win.filter invoke"
    bind $win.sel <KeyPress-Return> "$win.ok     invoke"
    bind $win.l.lst <ButtonRelease-1> \
        "+selInsert $win \[%W get \[ %W nearest %y \] \] "
    bind $win.l.lst <Double-1> \
        "selInsert $win \[%W get \[%W curselection\]\];  $win.ok invoke"


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
    update
    set w [winfo width  $::arena_c]
    set h [winfo height $::arena_c]

    if {$w < $h} {
        set val [- $w 20]
    } else {
        set val [- $h 20]
    }

    set ::scale  [/ $val 1000.0]
    #set ::border 0
    #set ::side   [- [int [* 1000 $::scale]] [* 2 $::border]]
    set ::side   [int [* 1000 $::scale]]

    #set b  $::border
    #set sb [+ $::side $::border]
    #$::arena_c configure -scrollregion "$b $b $sb $sb"

    $::arena_c delete wall

    # Put an invisible rectangle outside to create some padding in the bbox
    $::arena_c create rectangle -8 -8 [+ $::side 8] [+ $::side 8] -tags wall \
            -outline "" -fill ""
    $::arena_c create rectangle 0 0 $::side $::side -tags wall -width 2

    $::arena_c configure -scrollregion [$::arena_c bbox wall]
}

proc border_check {coord} {
    # Debug fix:
    return $coord

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
    foreach robot $::allRobots {
        # check robots
        if {$::data($robot,status)} {
            set x [border_check [* $::data($robot,x) $::scale]]
            set y [border_check [* [- 1000 $::data($robot,y)] $::scale]]
            #puts "loc $robot $x ($::data($robot,x)) $y ($::data($robot,y))"
            $::arena_c coords $::data($robot,robotid) $x $y \
                    [expr {$x+($::c_tab($::data($robot,hdg))*5)}] \
                    [expr {$y-($::s_tab($::data($robot,hdg))*5)}]
        }
        # check missiles
        if {$::data($robot,mstate)} {
            $::arena_c delete m$::data($robot,num)
            set x [border_check [* $::data($robot,mx) $::scale]]
            set y [border_check [* [- 1000 $::data($robot,my)] $::scale]]
            $::arena_c create oval \
                    [- $x 2] [- $y 2] [+ $x 2] [+ $y 2] \
                    -fill black -tags m$::data($robot,num)
        }
    }
}



###############################################################################
#
# show scanner from a robot
#
#

proc show_scan {} {
    # Hide the scan arcs by default
    $::arena_c itemconfigure scan -outline ""

    foreach robot $::activeRobots {
        # Hide the scan arc by default
        $::arena_c itemconfigure $::data($robot,scanid) -outline ""

        if {$::data($robot,status)} {
            lassign $::data($robot,syscall,$::tick) cmd deg res
            if {($cmd eq "scanner") && \
                    ($::data($robot,syscall,$::tick) eq \
                    $::data($robot,syscall,[- $::tick 1]))} {

                #puts "deg: $deg, res: $res"

                set x [border_check [* $::data($robot,x) $::scale]]
                set y [border_check [* [- 1000 $::data($robot,y)] $::scale]]
                #puts "scan $robot $x $y"
                set val [* $::parms(mismax) $::scale]
                $::arena_c coords $::data($robot,scanid) \
                        [- $x $val] [- $y $val] \
                        [+ $x $val] [+ $y $val]
                $::arena_c itemconfigure $::data($robot,scanid) \
                        -start [expr {$deg-$res}] \
                        -extent [expr {2*$res + 1}] \
                        -outline $::data($robot,color)
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
    after 200 "$::arena_c delete e$::data($robot,num)"
}

proc show_health {} {
    set ::robotHealth {}
    set index 0
    foreach robot $::allRobots {
        lappend ::robotHealth "$::data($robot,name) $::data($robot,health)"
        $::robotHealth_lb itemconfigure $index -foreground $::data($robot,color)
        if {$::data($robot,brightness) > 0.5} {
            $::robotHealth_lb itemconfigure $index -background black
        }
        incr index
    }
}

proc brightness color {
    foreach {r g b} [winfo rgb . $color] break
    set max [lindex [winfo rgb . white] 0]
    expr {($r*0.3 + $g*0.59 + $b*0.11)/$max}
 } ;#RS, after [Kevin Kenny]

proc show_msg {robot msg} {
    lappend ::robotMsg "$robot: $msg"
    $::robotMsg_lb itemconfigure end -foreground $::data($robot,color)

    if {$::data($robot,brightness) > 0.5} {
        $::robotMsg_lb itemconfigure end -background black
    }

    $::robotMsg_lb see end
}

#
# Returns a list of colors. From http://wiki.tcl.tk/666
#
proc distinct_colors {n} {
    set nn 1
    set hue_increment .15
    set s 1.0 ;# non-variable saturation

    set lum_steps [expr {$n * $hue_increment}]
    set int_lum_steps [int $lum_steps]
    if {$lum_steps > $int_lum_steps} { ;# round up
        set lum_steps [+ $int_lum_steps 1]
    }
    set lum_increment [/ .7 $lum_steps]

    for {set l 1.0} {$l > 0.3} {set l [expr {$l - $lum_increment}]} {
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
        set c1 [format %02X $intc]
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

    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}

    # start robots
    $::info_l configure -text "Running"
    set ::execCmd halt
    $::run_b   configure -state normal    -text "Halt"
    $::sim_b   configure -state disabled
    $::tourn_b configure -state disabled
    $::about_b configure -state disabled
    $::quit_b  configure -state disabled

    # Init robots
    init

    # Give the robots colors
    set ::colors [distinct_colors [llength $::robotFiles]]

    # Remove old canvas items
    $::arena_c delete robot
    $::arena_c delete scan

    set i 0
    foreach robot $::allRobots color $::colors {
        # Set colors as far away as possible from each other visually
        set ::data($robot,color) $color
        set ::data($robot,brightness) [brightness $color]
        # Precreate robot on canvas
        set ::data($robot,shape) [lindex $::parms(shapes) [% $i 4]]
        set ::data($robot,robotid) [$::arena_c create line -100 -100 -100 -100 \
                -fill $::data($robot,color) \
                -arrow last -arrowshape $::data($robot,shape) \
                -tags "r$::data($robot,num) robot"]
        # Precreate scan mark on canvas
        set ::data($robot,scanid) [$::arena_c create arc -100 -100 -100 -100 \
                -start 0 -extent 0 -fill "" -outline "" -stipple gray50 \
                -width 1 -tags "scan s$::data($robot,num)"]

        incr i
    }

    # Start game
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
    if {!$::gui} return

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
    set x [expr {[winfo screenwidth $w]/2 - [winfo reqwidth $w]/2  - \
            [winfo vrootx [winfo parent $w]]}]
    set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2  - \
            [winfo vrooty [winfo parent $w]]}]
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
    destroy $::game_f.sim
    grid $::sel_f -column 0 -row 2 -sticky nsew
    $::info_l configure -text "Select robot files for battle"
    $::run_b   configure -state normal
    $::sim_b   configure -state normal
    $::tourn_b configure -state normal
    $::about_b configure -state normal
    $::quit_b  configure -state normal
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

proc gui_settings {} {
    # Copy some settings from Ttk to Tk
    set bg [ttk::style configure . -background]
    option add *Listbox.background $bg
    option add *Menubutton.background $bg
    option add *Menu.background $bg
}

proc init_gui {} {
    gui_settings

    # Create and grid the outer content frame
    # The button row
    grid columnconfigure . 0 -weight 1
    # The content frames sel and game
    grid rowconfigure    . 2 -weight 1

    set ::execCmd init_arena

    # Create button frame and buttons
    set ::buttons_f [ttk::frame .f1]
    set ::run_b     [ttk::button .f1.b0 -text "Run Battle" \
                         -command {eval $::execCmd}]
    set ::sim_b     [ttk::button .f1.b1 -text "Simulator" \
                         -command {source $::thisDir/simulator.tcl; init_sim}]
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
    #catch {destroy .iconm}
    #toplevel .iconm
    #grid [label .iconm.i -image iconfn]

    wm title . "TclRobots"
    #wm iconwindow . .iconm
    wm iconname . TclRobots
    wm protocol . WM_DELETE_WINDOW "catch {$::quit_b invoke}"

    # The info label
    set ::info_l [ttk::label .l -relief solid \
                      -text "Select robot files for battle"]

    # The contents frame contains two frames
    set ::sel_f [ttk::frame .f2]

    # Contents left frame
    set sel0_f [ttk::frame $::sel_f.fl -relief sunken -borderwidth 3]

    # Contents right frame
    set sel1_f [ttk::frame $::sel_f.fr -relief sunken -borderwidth 3]

    # The file selection box
    set files_fb [fileBox $::sel_f.fl "Select" *.tr "" [pwd] choose_file]

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
    #set ::game_f [ttk::frame .f3 -width 520 -height 520]
    set ::game_f [ttk::frame .f3]

    # The battle field canvas
    set ::arena_c [canvas $::game_f.c -background white]
    bind $::arena_c <Configure> {show_arena}

    # The robot health list
    set ::robotHealth {}
    set ::robotHealth_lb [listbox $::game_f.h -background black \
                              -listvariable ::robotHealth]

    # The robot message box
    set ::robotMsg {}
    set ::robotMsg_lb [listbox $::game_f.msg -background black \
                           -listvariable ::robotMsg]

    grid $::arena_c        -column 0 -row 0 -rowspan 2 -sticky nsew
    grid $::robotHealth_lb -column 1 -row 0            -sticky nsew
    grid $::robotMsg_lb    -column 1 -row 1            -sticky nsew
    grid columnconfigure $::game_f 0 -weight 1
    grid rowconfigure    $::game_f 0 -weight 1
    grid columnconfigure $::game_f 1 -weight 1

}

proc update_gui {} {
    show_robots
    show_scan
    show_health
    update
}