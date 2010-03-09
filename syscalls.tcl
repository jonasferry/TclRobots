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
#   Jonas Ferry (jonas.ferry@gmail.com), 2010. See LICENSE file for
#   details.
#
#******

#****** syscalls/helper
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

#****p* helper/_ping_check
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

#****p* helper/_syscall_yield
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

#****** syscalls/basic_cmds
#
# NAME
#
#   basic_cmds
#
# DESCRIPTION
#
#   Basic commands
#
#******

#****i* syscalls/basic
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

#****iS* basic/scanner
#
# NAME
#
#   scanner
#
# DESCRIPTION
#
#   Cost: 2 ticks.
#
#******

#****p* basic_cmds/scanner
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

#****iS* basic/dsp
#
# NAME
#
#   dsp
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/dsp
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

#****iS* basic/alert
#
# NAME
#
#   alert
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/alert
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

#****iS* basic/cannon
#
# NAME
#
#   cannon
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/cannon
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

#****iS* basic/health
#
# NAME
#
#   health
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/health
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

#****iS* basic/drive
#
# NAME
#
#   drive
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/drive
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

#****iS* basic/speed
#
# NAME
#
#   speed
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/speed
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

#****iS* basic/heat
#
# NAME
#
#   heat
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/heat
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

#****iS* basic/loc_x
#
# NAME
#
#   loc_x
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/loc_x
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

#****iS* basic/loc_y
#
# NAME
#
#   loc_y
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/loc_y
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

#****iS* basic/tick
#
# NAME
#
#   tick
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* basic_cmds/tick
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

#****** syscalls/team_cmds
#
# NAME
#
#   team_cmds
#
# DESCRIPTION
#
#   Team commands
#
#******

#****i* syscalls/team
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

#****iS* team/team_declare
#
# NAME
#
#   team_declare
#
# DESCRIPTION
#
#   Cost: 1 tick.
#
#******

#****p* team_cmds/team_declare
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

#****iS* team/team_send
#
# NAME
#
#   team_send
#
# DESCRIPTION
#
#   Cost: 0 ticks.
#
#******

#****p* team_cmds/team_send
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

#****iS* team/team_get
#
# NAME
#
#   team_get
#
# DESCRIPTION
#
#   Cost: 0 ticks.
#
#******

#****p* team_cmds/team_get
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

#****** syscalls/convenience_cmds
#
# NAME
#
#   convenience_cmds
#
# DESCRIPTION
#
#   Convenience commands
#
#******

#****i* syscalls/convenience
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

#****iS* convenience/dputs
#
# NAME
#
#   dputs
#
# DESCRIPTION
#
#   Cost: 0 ticks.
#
#******

#****p* convenience_cmds/dputs
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

#****iS* convenience/rand
#
# NAME
#
#   rand
#
# DESCRIPTION
#
#   Cost: 0 ticks.
#
#******

#****p* convenience_cmds/rand
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

#****iS* convenience/callback
#
# NAME
#
#   callback
#
# DESCRIPTION
#
#   Cost: 0 ticks.
#
#******

#****p* convenience_cmds/callback
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

#****** syscalls/deprecated_cmds
#
# NAME
#
#   deprecated_cmds
#
# DESCRIPTION
#
#   Deprecated commands kept for backwards compatibility.
#
#******

#****p* deprecated_cmds/after
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
