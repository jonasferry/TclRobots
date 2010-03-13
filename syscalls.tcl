#****F* syscalls/file_header
#
# NAME
#
#   syscalls.tcl
#
# DESCRIPTION
#
#   This file contains the syscalls robots can use.
#
#   The authors are Jonas Ferry, Peter Spjuth and Martin Lindskog, based
#   on TclRobots 2.0 by Tom Poindexter.
#
#   See http://tclrobots.org for more information.
#
# COPYRIGHT
#
#   Jonas Ferry (jonas.ferry@gmail.com), 2010. Licensed under the
#   Simplified BSD License. See LICENSE file for details.
#
#******

#****I* syscalls/helper
#
# NAME
#
#   helper
#
# DESCRIPTION
#
#   Helper procedures
#
#******

#****P* helper/_ping_check
#
# NAME
#
#   _ping_check
#
# DESCRIPTION
#
#   Check the answer from a yield for a ping alert
#
# SOURCE
#
proc _ping_check {val} {
    if {[lindex $val 0] eq "alert"} {
        #  ping_proc:        dsp:
        [lindex $val 1] [lindex $val 2]
        set val [lrange $val 3 end]
    }
    return $val
}
#******

#****P* helper/_syscall_yield
#
# NAME
#
#   _syscall_yield
#
# DESCRIPTION
#
#   Combine the common syscall+yield call
#
# SOURCE
#
proc _syscall_yield {args} {
    set result [syscall callbackcheck]
    if {$result ne ""} {
        uplevel \#0 $result
    }
    syscall {*}$args
    return [_ping_check [yield]]
}
#******

#****I* syscalls/basic
#
# NAME
#
#   basic
#
# DESCRIPTION
#
#   Basic commands
#
#******

#****P* basic/scanner
#
# NAME
#
#   scanner
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc scanner {degree resolution} {
    _syscall_yield scanner $degree $resolution
    _syscall_yield scanner $degree $resolution
}
#******

#****P* basic/dsp
#
# NAME
#
#   dsp
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc dsp {} {
    _syscall_yield dsp
}
#******

#****P* basic/alert
#
# NAME
#
#   alert
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc alert {procname} {
    _syscall_yield alert $procname
}
#******

#****P* basic/cannon
#
# NAME
#
#   cannon
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc cannon {degree range} {
    _syscall_yield cannon $degree $range
}
#******

#****P* basic/health
#
# NAME
#
#   health
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc health {} {
    _syscall_yield health
}
#******

#****P* basic/drive
#
# NAME
#
#   drive
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc drive {degree speed} {
    _syscall_yield drive $degree $speed
}
#******

#****P* basic/speed
#
# NAME
#
#   speed
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc speed {} {
    _syscall_yield speed
}
#******

#****P* basic/heat
#
# NAME
#
#   heat
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc heat {} {
    _syscall_yield heat
}
#******

#****P* basic/loc_x
#
# NAME
#
#   loc_x
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc loc_x {} {
    _syscall_yield loc_x
}
#******

#****P* basic/loc_y
#
# NAME
#
#   loc_y
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc loc_y {} {
    _syscall_yield loc_y
}
#******

#****P* basic/tick
#
# NAME
#
#   tick
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc tick {} {
    _syscall_yield tick
}
#******

#****I* syscalls/team
#
# NAME
#
#   team
#
# DESCRIPTION
#
#   Team commands
#
#******

#****P* team/team_declare
#
# NAME
#
#   team_declare
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc team_declare {teamname} {
    _syscall_yield team_declare $teamname
}
#******

#****P* team/team_send
#
# NAME
#
#   team_send
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc team_send {data} {
    syscall team_send $data
}
#******

#****P* team/team_get
#
# NAME
#
#   team_get
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc team_get {} {
    syscall team_get
}
#******

#****I* syscalls/convenience
#
# NAME
#
#   convenience
#
# DESCRIPTION
#
#   Convenience commands
#
#******

#****P* convenience/dputs
#
# NAME
#
#   dputs
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc dputs {args} {
    syscall dputs $args
}
#******

#****P* convenience/rand
#
# NAME
#
#   rand
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc rand {max} {
    syscall rand $max
}
#******

#****P* convenience/callback
#
# NAME
#
#   callback
#
# DESCRIPTION
#
#   
#
# SOURCE
#
proc callback {time script} {
    syscall callback $time $script
}
#******

#****I* syscalls/deprecated
#
# NAME
#
#   deprecated
#
# DESCRIPTION
#
#   Deprecated commands kept for backwards compatibility.
#
#******

#****P* deprecated/after
#
# NAME
#
#   after
#
# DESCRIPTION
#
#   After does not work, emulate it using callbacks
#
# SOURCE
#
proc after {ms args} {
    set ticks [expr {$ms / 100}]
    if {[llength $args] == 0} {
        # Emulate a wait using some syscalls
        for {set t 0} {$t < $ticks} {incr t} {
            syscall speed
            return [_ping_check [yield]]
        }

    } else {
        set script [join $args]
        syscall callback $ticks $script
    }
    return
}
#******

#****P* deprecated/damage
#
# NAME
#
#   damage
#
# DESCRIPTION
#
#   damage
#
#   The damage command reports the current percent of damage suffered by
#   the robot, 0-99. At 100% damage, the robot is "dead", and as such,
#   the control program is no longer running.
#
# SOURCE
#

#******
