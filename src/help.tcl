#****F* help/file_header
#
# NAME
#
#   help.tcl
#
# DESCRIPTION
#
#   This file contains the GUI description of the TclRobots help window.
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

#****P* help/init_help
#
# NAME
#
#   init_help
#
# DESCRIPTION
#
#   Displays the README file in a separate text window.
#
# SOURCE
#
proc init_help {} {
    # Create new toplevel and apply some settings
    toplevel .help
    grid columnconfigure .help 0 -weight 1; grid rowconfigure .help 0 -weight 1

    # Create navigation
    set ::helpnav_f [ttk::frame .help.f1]
    set ::showhelp_b    [ttk::button $::helpnav_f.b1 -text "Show Help" \
                             -command {show_page help}]
    set ::showlicense_b [ttk::button $::helpnav_f.b2 -text "Show License" \
                             -command {show_page license}]
    set ::closehelp_b   [ttk::button $::helpnav_f.b3 -text "Close" \
                             -command {end_help}]

    # Grid the buttons
    grid $::showhelp_b    -column 0 -row 0 -sticky w
    grid $::showlicense_b -column 1 -row 0 -sticky w
    grid $::closehelp_b   -column 2 -row 0 -sticky w

    # Load the HTML extension
    set ::html_help 0

    switch $::tcl_platform(platform) {
        windows {
            if {![catch {load $::thisDir/../lib/tkhtml/tkhtml.dll}] } {
                set ::html_help 1
            }
        }
        unix {
            if {![catch {load $::thisDir/../lib/tkhtml/tkhtml.so}] } {
                set ::html_help 1
            }
        }
    }
    if {$::html_help} {
        # HTML is enabled, create HTML widget
        set ::help_t [html .help.t -hyperlinkcommand handle_link \
                          -base $::thisDir/doc/game_doc.html \
                          -yscrollcommand ".help.s set"]

        # Bind mouse clicks
        bind .help <ButtonRelease-1> "handle_click %x %y"

        # Bind mouse scroll wheel
        if {[string equal "unix" $::tcl_platform(platform)]} {
            bind all <4> "+handle_scrollwheel %X %Y -1"
            bind all <5> "+handle_scrollwheel %X %Y 1"
        }
        bind all <MouseWheel> "+handle_scrollwheel %X %Y %D"

        # Read the HTML help doc
        set f [open $::thisDir/../doc/game_doc.html]
        set ::help_text [read $f]
        close $f

        # Read the license doc, add <pre> formatting
        set f [open $::thisDir/../LICENSE]
        set ::license_text "<pre>[read $f]</pre>"
        close $f
    } else {
        # HTML is disabled, create text widget
        set ::help_t [tk::text .help.t -width 80 -height 30 -wrap word \
                        -yscrollcommand ".help.s set"]

        # Read the plain text help doc
        set f [open $::thisDir/../README]
        set ::help_text [read $f]
        close $f

        # Read the license doc
        set f [open $::thisDir/../LICENSE]
        set ::license_text [read $f]
        close $f
    }

    # Create scrollbar for help doc window
    set help_s [ttk::scrollbar .help.s -command ".help.t yview" \
                    -orient vertical]

    # Grid the text box and scrollbar
    grid $::helpnav_f -column 0 -row 0 -sticky nsew
    grid $::help_t    -column 0 -row 1 -sticky nsew
    grid $help_s      -column 1 -row 1 -sticky ns

    show_page help
}
#******

#****P* init_help/show_page
#
# NAME
#
#   show_page
#
# SYNOPSIS
#
#   show_page page
#
# DESCRIPTION
#
#   Show the requested page text in Help browser. Checks if HTML is
#   enabled or not.
#
# SOURCE
#
proc show_page {page} {
    if {$page eq "help"} {
        set text $::help_text
    } else {
        set text $::license_text
    }
    if {$::html_help} {
        # Clear and insert new text into HTML widget
        $::help_t clear
        $::help_t parse $text
    } else {
        # Insert text into text box
        $::help_t delete 1.0 end
        $::help_t insert 1.0 $text
    }
}
#******

#****P* init_help/end_help
#
# NAME
#
#   end_help
#
# DESCRIPTION
#
#   Closes the help browser.
#
# SOURCE
#
proc end_help {} {
    destroy .help
}
#******

#****P* init_help/handle_click
#
# NAME
#
#   handle_click
#
# SYNOPSIS
#
#   handle_click x y
#
# DESCRIPTION
#
#   Handle clicks on and off links in HTML widget. Called with the x and
#   y coordinates of the click. Uses href widget command to figure out
#   if a link was clicked.
#
#   Currently handles anchor links and the license link.
#
# SOURCE
#
proc handle_click {x y} {
    # Must make sure that Close button has not destroyed the widget
    # before accessing it
    if {[winfo exists $::help_t]} {
        set link [$::help_t href $x $y]
        if {$link eq \
                "http://github.com/jonasferry/TclRobots/blob/master/LICENSE"} {
            show_page license
        } else {
            $::help_t yview [lindex [split $link #] 1]
        }
    }
}
#******

#****P* init_help/handle_scrollwheel
#
# NAME
#
#   handle_scrollwheel
#
# SYNOPSIS
#
#   handle_click x y
#
# DESCRIPTION
#
#   Handles the mouse scrollwheel in the help browser.
#
#   From: http://code.activestate.com/recipes/68394/
#
# SOURCE
#
proc handle_scrollwheel { x y delta } {

    # Find out what's the widget we're on
    set act 0
    set widget [winfo containing $x $y]

    if {$widget != ""} {
        # Make sure we've got a vertical scrollbar for this widget
        if {[catch "$widget cget -yscrollcommand" cmd]} return

        if {$cmd != ""} {
            # Find out the scrollbar widget we're using
            set scroller [lindex $cmd 0]

            # Make sure we act
            set act 1
        }
    }

    if {$act == 1} {
        # Now we know we have to process the wheel mouse event
        set xy [$widget yview]
        set factor [expr [lindex $xy 1]-[lindex $xy 0]]

        # Make sure we activate the scrollbar's command
        # The following line is original, but the second line works.
#        set cmd "[$scroller cget -command] scroll [expr -int($delta/(120*$factor))] units"
        set cmd "[$scroller cget -command] scroll $delta units"
        eval $cmd
    }
}
#******