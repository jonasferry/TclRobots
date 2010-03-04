package require Tk
# Try to get tkpath
if {[catch {package require tkpath}]} {
    if {[file exists libtkpath0.3.1.dylib]} {
        catch {
            # Try for a local copy
            load ./libtkpath0.3.1.dylib
            source tkpath.tcl
            package require tkpath
        }
    } elseif {[file exists libtkpath0.3.1.so]} {
        catch {
            # Try for a local copy
            load ./libtkpath0.3.1.so
            source tkpath.tcl
            package require tkpath
        }
    	
    }
}

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
    lappend ::robotList $filename
    set dir $filename
    foreach d $::robotList {
        if {[string length $d] > [string length $dir]} {
            set dir $d
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
    set win $::files_fb
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
    catch {set index [$::robotlist_lb curselection]}
    if {$index >= 0} {
        $::robotlist_lb delete $index
    }
}


###############################################################################
#
# remove_all
#
proc remove_all {} {
    set ::robotList {}
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
    set all_list [lsort -dictionary [glob -nocomplain -type d $dir/*]]
    lappend all_list \
            {*}[lsort -dictionary [glob -nocomplain -type f $dir/$filt]]

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
    bind $win.l.lst <Double-1> "$win.ok invoke"


    fillLst $win $filt $startdir
    selection own $win
    focus $win.sel
    return $win
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
    set ::StatusBarMsg "Standby, cleaning up any left overs...."
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
    set ::side   [int [* 1000 $::scale]]

    $::arena_c delete wall

    # Put an invisible rectangle outside to create some padding in the bbox
    $::arena_c create rectangle -8 -8 [+ $::side 8] [+ $::side 8] -tags wall \
            -outline "" -fill ""
    $::arena_c create rectangle 0 0 $::side $::side -tags wall -width 2

    $::arena_c configure -scrollregion [$::arena_c bbox wall]
}

###############################################################################
#
# update canvas with position of missiles and robots
#
#

proc show_robots {} {
    $::arena_c delete highlight
    foreach robot $::allRobots {
        # check robots
        if {$::data($robot,status)} {
            set x [* $::data($robot,x) $::scale]
            set y [* [- 1000 $::data($robot,y)] $::scale]
            #puts "loc $robot $x ($::data($robot,x)) $y ($::data($robot,y))"
            if {$::data(tkp)} {
                set val [* 4 $::scale]
                set cosPhi [expr {$::c_tab($::data($robot,hdg))*$val}]
                set sinPhi [expr {$::s_tab($::data($robot,hdg))*$val}]
                set msinPhi [- $sinPhi]
		set matrix \
                        [list [list $cosPhi $msinPhi] [list $sinPhi $cosPhi] \
                        [list $x $y]]
                $::arena_c itemconfigure $::data($robot,robotid) \
                        -matrix $matrix
            } else {
                $::arena_c coords $::data($robot,robotid) $x $y \
                        [expr {$x+($::c_tab($::data($robot,hdg))*5)}] \
                        [expr {$y-($::s_tab($::data($robot,hdg))*5)}]
            }
            if {$::data($robot,highlight)} {
                set r [* 50 $::scale]
                $::arena_c create oval \
                        [- $x $r] [- $y $r] [+ $x $r] [+ $y $r] \
                        -outline $::data($robot,color) -tags highlight
                $::arena_c lower highlight
            }
        }
        # check missiles
        if {$::data($robot,mstate)} {
            $::arena_c delete m$::data($robot,num)
            set x [* $::data($robot,mx) $::scale]
            set y [* [- 1000 $::data($robot,my)] $::scale]
            set val [* 6 $::scale]
            if {$::data(tkp)} {
                $::arena_c create circle $x $y -r $val \
                        -fill $::data(gradient,miss) \
                        -fillopacity 0.7 -stroke "" -tags m$::data($robot,num)
            } else {
                $::arena_c create oval \
                        [- $x $val] [- $y $val] [+ $x $val] [+ $y $val] \
                        -fill black -tags m$::data($robot,num)
            }
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
    if {$::data(tkp)} {
        $::arena_c itemconfigure scan -fill ""
    } else {
        $::arena_c itemconfigure scan -outline ""
    }

    foreach robot $::activeRobots {
        if {$::data($robot,status)} {
            lassign $::data($robot,syscall,$::tick) cmd deg res
            if {($cmd eq "scanner") && \
                    ($::data($robot,syscall,$::tick) eq \
                    $::data($robot,syscall,[- $::tick 1]))} {

                #puts "deg: $deg, res: $res"

                set x [* $::data($robot,x) $::scale]
                set y [* [- 1000 $::data($robot,y)] $::scale]
                #puts "scan $robot $x $y"
                set val [* $::parms(mismax) $::scale]
                if {$::data(tkp)} {
                    set path [arc_path [expr {$deg-$res}] [expr {2*$res + 1}]]
                    # Scale to radius and move to location
                    set matrix [list [list $val 0] [list 0 $val] [list $x $y]]
                    $::arena_c coords $::data($robot,scanid) $path
                    $::arena_c itemconfigure $::data($robot,scanid) \
                            -fill $::data($robot,color) -matrix $matrix
                } else {
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
}

###############################################################################
#
# show explosion of missile
#
#

proc show_explode {robot} {
    # Delete the missile
    $::arena_c delete m$::data($robot,num)

    set x [* $::data($robot,mx) $::scale]
    set y [* [- 1000 $::data($robot,my)] $::scale]

    if {$::data(tkp)} {
        set id [$::arena_c create circle $x $y -r 0 \
                -fill $::data(gradient,expl) \
                -fillopacity 0.7 -stroke "" -tags e$::data($robot,num)]
                
        #Loop over all animation frames       
        for {set i 0} {$i < $::parms(explosion,numbooms)} {incr i} {
	    after [expr $::parms(explosion,duration)/$::parms(explosion,numbooms)*$i] [string map [list %id% $id %val% [expr 40*$i*$::scale/$::parms(explosion,numbooms)]] {
                $::arena_c itemconfigure %id% -r %val%
            }]
        }
    } else {
    	set val [* 6 $::scale] ; #It's easier that way
        set val2 [* 10 $::scale]
        set val3 [* 20 $::scale]
        set val4 [* 40 $::scale]
        set id [$::arena_c create oval \
                [- $x $val] [- $y $val] [+ $x $val] [+ $y $val] \
                -outline red    -fill red     -width 1  \
                -tags e$::data($robot,num)]
        set coords2 [list [- $x $val2] [- $y $val2] [+ $x $val2] [+ $y $val2]]
        set coords3 [list [- $x $val3] [- $y $val3] [+ $x $val3] [+ $y $val3]]
        set coords4 [list [- $x $val4] [- $y $val4] [+ $x $val4] [+ $y $val4]]

        update
        after 100 [string map [list %id% $id %coords% $coords2] {
            $::arena_c itemconfigure %id% -outline orange -fill red
            $::arena_c coords %id% %coords%
        }]
        after 200 [string map [list %id% $id %coords% $coords3] {
            $::arena_c itemconfigure %id% -outline yellow -fill orange
            $::arena_c coords %id% %coords%
        }]
        after 300 [string map [list %id% $id %coords% $coords4] {
            $::arena_c itemconfigure %id% -outline yellow -fill yellow
            $::arena_c coords %id% %coords%
        }]
    }
    after [expr $::parms(explosion,duration)+100] "$::arena_c delete e$::data($robot,num)"
}

###############################################################################
#
# show effect when robot dies
#
#

proc show_die {robot} {	
    set x [* $::data($robot,x) $::scale]
    set y [* [- 1000 $::data($robot,y)] $::scale]

    set val [* 20 $::scale]
    set id [$::arena_c create oval \
            [- $x $val] [- $y $val] [+ $x $val] [+ $y $val] \
            -outline red    -fill ""     -width 1  \
            -tags die$::data($robot,num)]
    set val [* 30 $::scale]
    set coords2 [list [- $x $val] [- $y $val] [+ $x $val] [+ $y $val]]
    set val [* 40 $::scale]
    set coords3 [list [- $x $val] [- $y $val] [+ $x $val] [+ $y $val]]
    set val [* 50 $::scale]
    set coords4 [list [- $x $val] [- $y $val] [+ $x $val] [+ $y $val]]
    set val [* 60 $::scale]
    set coords5 [list [- $x $val] [- $y $val] [+ $x $val] [+ $y $val]]

    update
    after 100 [string map [list %id% $id %coords% $coords2] {
        $::arena_c coords %id% %coords%
        
    }]
    after 200 [string map [list %id% $id %coords% $coords3] {
        $::arena_c coords %id% %coords%
    }]
    after 300 [string map [list %id% $id %coords% $coords4] {
        $::arena_c coords %id% %coords%
        
    }] 
    after 400 [string map [list %id% $id %coords% $coords5] {
        $::arena_c coords %id% %coords%
    }]
    after 500 "$::arena_c delete die$::data($robot,num)"
}

proc show_health {} {
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

# Highlight a robot selected in health listbox
proc highlightRobot {} {
    foreach robot $::allRobots {
        set ::data($robot,highlight) 0
    }
    set sel [$::robotHealth_lb curselection]

    if {[string is integer -strict $sel]} {
        set robot [lindex $::allRobots $sel]
        set ::data($robot,highlight) 1
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

proc create_arena {} {
    # The battle field canvas
    if {[info commands ::tkp::canvas] ne ""} {
        set ::arena_c [tkp::canvas $::game_f.c -background white]
        set ::data(tkp) 1

        # A gradient for a ball. Used for explosion
        set ::data(gradient,expl) [$::arena_c gradient create radial \
                -stops "{0 red 0.8} {1 yellow 0}" \
                -radialtransition {0.5 0.5 0.5 0.5 0.5}]
        # A gradient for a ball. Used for missile
        set ::data(gradient,miss) [$::arena_c gradient create radial \
                -stops "{0 darkgray} {1 black}" \
                -radialtransition {0.6 0.4 0.8 0.7 0.3}]
    } else {
        set ::arena_c [canvas $::game_f.c -background white]
        set ::data(tkp) 0
    }
    bind $::arena_c <Configure> {show_arena}
}

proc gui_init_robots {{lastblack 0}} {
    # Give the robots colors
    set colors [distinct_colors [llength $::allRobots]]

    # For the simulator, force the last robot to be black
    if {$lastblack} {
        lset colors end black
    }

    # Remove old canvas items
    $::arena_c delete robot
    $::arena_c delete scan
	
    set i 0
    foreach robot $::allRobots color $colors {
        # Set colors as far away as possible from each other visually
        set ::data($robot,color) $color
        set ::data($robot,brightness) [brightness $color]
        # Precreate robot on canvas
        set ::data($robot,shape) [lindex $::parms(shapes) [% $i 4]]
        set ::data($robot,paths) [lindex $::parms(paths) [% $i [llength $::parms(paths)]]]
        if {$::data(tkp)} {
            foreach path $::data($robot,paths) {
                $::arena_c create path $path \
                        -fill "" -stroke $color \
                        -tags "robot r$::data($robot,num)"
            }
            set ::data($robot,robotid) r$::data($robot,num)
        } else {
            set ::data($robot,robotid) [$::arena_c create line \
                    -100 -100 -100 -100 \
                    -fill $::data($robot,color) \
                    -arrow last -arrowshape $::data($robot,shape) \
                    -tags "r$::data($robot,num) robot"]
        }
        set ::data($robot,highlight) 0
        # Precreate scan mark on canvas
        if {$::data(tkp)} {
            set path [arc_path 0 1]
            set ::data($robot,scanid) [$::arena_c create path $path \
                    -fill "" -fillopacity 0.2 -stroke "" \
                    -tags "scan s$::data($robot,num)"]
        } else {
            set ::data($robot,scanid) [$::arena_c create arc -100 -100 -100 -100 \
                    -start 0 -extent 0 -fill "" -outline "" -stipple gray50 \
                    -width 1 -tags "scan s$::data($robot,num)"]
        }

        incr i
    }
}
    
# Create a path for a pie-slice circular arc, center in origo, radius 1
proc arc_path {phi extend} {
    set path [list M 0 0]

    set phiRad    [expr {$phi/180.0*3.1415926}]
    set extendRad [expr {$extend/180.0*3.1415926}]

    set x1 [expr {cos($phiRad)}]
    set y1 [expr {-sin($phiRad)}]
    lappend path L $x1 $y1

    set x2 [expr {cos($phiRad+$extendRad)}]
    set y2 [expr {-sin($phiRad+$extendRad)}]
    lappend path A 1 1 0 [expr {$extend > 180}] 0 $x2 $y2

    lappend path Z
    return $path
}

###############################################################################
#
# start a match
#
#

proc init_battle {} {
    
    if {[llength $::robotList] < 2} {
    	tk_dialog2 .morerobots "More robots!" "Please select at least two robots" "-image iconfn" 0 dismiss
        return
    }

    set ::halted  0
	
    set ::StatusBarMsg "Initializing..."
	
    # get robot filenames from window
    set ::robotFiles $::robotList
	
    grid forget $::sel_f
    grid $::game_f -column 0 -row 2 -sticky nsew
    show_arena
	
    # Clear message boxes
    set ::robotHealth {}
    set ::robotMsg    {}
	
    # start robots
    set ::StatusBarMsg "Running"
    $::run_b   configure -state normal   -text "Halt" -command halt
    $::sim_b   configure -state disabled
    $::tourn_b configure -state disabled
    $::about_b configure -state disabled
    $::quit_b  configure -state disabled
	
    # Init robots
    init

    # Init robots on GUI
    gui_init_robots

    # Start game
    main
	
    # find winnner
    if {$::halted} {
        set ::StatusBarMsg "Battle halted"
    } else {
        tk_dialog2 .winner "Results" $::win_msg "-image iconfn" 0 dismiss
    }
	
    $::run_b configure -state normal -text "Reset" -command reset
}

# standard tk_dialog modified to use -image on label

proc tk_dialog2 {w title text bitmap default args} {
    if {!$::gui} return

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    catch {destroy $w}
    toplevel $w -class Dialog
    if {[tk windowingsystem] eq "aqua"} {
        # Trick to try to get rid of the odd-looking resize grip on Mac
        wm resizable $w 0 0
    }
    ttk::frame $w.background
    place $w.background -x 0 -y 0 -relwidth 1.0 -relheight 1.0
    wm title $w $title
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW { }
    wm transient $w [winfo toplevel [winfo parent $w]]
    ttk::frame $w.top
    pack $w.top -side top -fill both
    ttk::frame $w.bot
    pack $w.bot -side bottom -fill both

    # 2. Fill the top part with bitmap and message.

    ttk::label $w.msg -wraplength 3i -justify left -text $text
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
        ttk::label $w.bitmap $type $bitmap
        pack $w.bitmap -in $w.top -side left -padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach but $args {
        ttk::button $w.button$i -text $but -command "set ::tkPriv(button) $i"
        if {$i == $default} {
            $w.button$i configure -default active
            #frame $w.default -relief sunken -bd 1
            #raise $w.button$i $w.default
            #pack $w.default -in $w.bot -side left -expand 1 -padx 3m -pady 2m
            pack $w.button$i -padx 2m -pady 2m
            bind $w <Return> "set tkPriv(button) $i"
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
    set ::running 0
    set ::StatusBarMsg "Stopping battle, standby"
    set ::halted 1

    $::run_b   configure -state normal -text "Reset" -command reset
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

    if {$::data(tkp)} {
        $::arena_c delete {*}[$::arena_c children 0]
    } else {
        $::arena_c delete all
    }

    grid forget $::game_f
    destroy $::game_f.sim
    grid $::sel_f -column 0 -row 2 -sticky nsew

    set ::StatusBarMsg "Select robot files for battle"
    $::run_b   configure -state normal -text "Run Battle" -command init_battle
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

proc ellipsepath {x y rx ry} {
    list \
            M $x [- $y $ry] \
            a $rx $ry 0 1 1 0 [*  2 $ry] \
            a $rx $ry 0 1 1 0 [* -2 $ry] \
            Z
}

proc gui_settings {} {
    # Copy some settings from Ttk to Tk
    set bg [ttk::style configure . -background]
    option add *Listbox.background $bg
    option add *Menubutton.background $bg
    option add *Menu.background $bg
}

proc init_gui {} {
    gui_settings
    
    set ::parms(explosion,numbooms) 20  ; #Number of frames in an explosion
    set ::parms(explosion,duration) 300 ; #Duration of an explosion
    set ::parms(shapes) {{3 12 7} {8 12 5} {11 11 3} {12 8 4}}
    set ::parms(paths)  {}
    set path [list [list M 10 0 L -5 5 L -5 -5 Z] "M 6 0 L -1 0"]
    lappend ::parms(paths) $path
    set path [list [list M 10 0 L -5 7 L 0 0 L -5 -7 Z]]
    lappend ::parms(paths) $path
    set path [list [ellipsepath 0 0 10 5] [ellipsepath 0 0 3 3]]
    lappend ::parms(paths) $path

    # Create and grid the outer content frame
    # The button row
    grid columnconfigure . 0 -weight 1
    # The content frames sel and game
    grid rowconfigure    . 2 -weight 1

    # Create button frame and buttons
    set ::buttons_f [ttk::frame .f1]
    set ::run_b     [ttk::button .f1.b0 -text "Run Battle" -command init_battle]
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

    wm title . "TclRobots"
    wm iconname . TclRobots
    wm protocol . WM_DELETE_WINDOW "catch {$::quit_b invoke}"

    # The info label
    set ::StatusBarMsg "Select robot files for battle"
    set info_l [ttk::label .l -textvariable ::StatusBarMsg -anchor w]

    # Add a size grip over the status bar
    ttk::sizegrip .sg
    place .sg -anchor se -relx 1.0 -rely 1.0

    # The contents frame contains two frames
    set ::sel_f [ttk::frame .f2]

    # Contents left frame
    set sel0_f [ttk::frame $::sel_f.fl -relief sunken -borderwidth 1]

    # Contents right frame
    set sel1_f [ttk::frame $::sel_f.fr -relief sunken -borderwidth 1]

    # The file selection box
    set ::files_fb [fileBox $::sel_f.fl "Select" *.tr "" [pwd] choose_file]

    # The robot list info label
    set robotlist_l  [ttk::label $::sel_f.fr.l -text "Robot files selected"]

    # A frame with the robot list and a scrollbar
    set robotlist_f  [ttk::frame $::sel_f.fr.f]

    # The robot list
    set ::robotList {}
    set ::robotlist_lb [listbox $::sel_f.fr.f.lb -relief sunken  \
                            -yscrollcommand "$::sel_f.fr.f.s set" \
                            -selectmode single -listvariable ::robotList]

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

    grid $info_l         -column 0 -row 3 -sticky nsew
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

    create_arena

    # The robot health list
    set ::robotHealth {}
    set ::robotHealth_lb [listbox $::game_f.h -background black \
                              -listvariable ::robotHealth]
    bind $::robotHealth_lb <<ListboxSelect>> highlightRobot

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
