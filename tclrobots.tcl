#****F* tclrobots/file_header
#
# NAME
#
#   tclrobots.tcl
#
# DESCRIPTION
#
#   This is the top-level file of TclRobots. It sources src/main.tcl
#   which includes the main game logic.
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

set version "3.0-alpha (2011-09-20)"

# Provide package name for starpack build, see Makefile
package provide app-tclrobots 1.0

set thisScript [file join [pwd] [info script]]
set thisDir [file dirname $thisScript]

source [file join $thisDir src/main.tcl]
