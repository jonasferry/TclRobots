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

#****I* syscalls/basic_cmds
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

#****iI* syscalls/basic
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
#   scanner degree resolution
#
# DESCRIPTION
#
#   The scanner command invokes the robot's scanner. Degree must be in
#   the range 0-359. Scanner returns 0 if nothing found, or an integer
#   greater than zero indicating the distance to an opponent. Resolution
#   controls how wide in degrees the scan can detect opponents from the
#   absolute scanning direction, and must be in the range 0-10. A robot
#   that has been destroyed is not reported by the scanner.
#
#   Cost: 2 ticks.
#
#******

#****P* basic_cmds/scanner
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
#   The dsp command returns a list of two integers, the first element is
#   the digital signature of the last robot found using the scanner.
#   The second element is the percent of damage the scanned robot has
#   accumulated, 0-99 percent. Each robot in a battle has a distinct
#   signature. If nothing was found during the last scan (scanner
#   command returned 0), then the dsp command will return "0 0".
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/dsp
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
#   alert proc-name
#
# DESCRIPTION
#
#   The alert command names a procedure to be called when the robot is
#   being scanned by another robot. When the robot detects it has been
#   scanned, the proc-name procedure is called with one argument, the
#   dsp signature of the robot that performed the scan. If proc-name is
#   null (""), then the alert feature is disabled.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/alert
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
#   cannon degree range
#
# DESCRIPTION
#
#   The cannon commands fires a shell in the direction specified by
#   degree, for the distance range. Cannon returns 1 if a shell was
#   fired; if the cannon is reloading, 0 is returned.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/cannon
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

#****P* basic_cmds/health
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
#   drive degree speed
#
# DESCRIPTION
#
#   The drive command starts the robot's drive mechanism. Degree must
#   be in the range 0-359. Speed must be in the range 0-100. Any
#   change in course that falls outside the "Degrees of course change"
#   table (see "The Robot", above) will cause the robot's speed to be
#   set to 0 along the current course. A speed of 0 causes the robot to
#   coast to a stop. The drive command returns the speed set. If the
#   drive is currently overheated, the maximum speed during overheating
#   (35%) will be set.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/drive
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
#   The speed command reports the current speed of the robot, 0-100.
#   Speed may return more or less than what was last set with the drive
#   command because of acceleration/deaccelearation, drive overheating,
#   or collision into a wall.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/speed
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
#   The heat command returns a list of two integers, the first element
#   is the overheating flag, 1 if the maximum motor heat value was
#   attained, otherwise 0. The second element is the current motor heat
#   index, 0-200.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/heat
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
#   The loc_x command returns the current x axis location of the robot,
#   0-999 meters.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/loc_x
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
#   The loc_y command returns the current y axis location of the robot,
#   0-999 meters.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/loc_y
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
#   The tick command returns the current clock tick. The clock tick is
#   set to 0 at game startup.
#
#   Cost: 1 tick.
#
#******

#****P* basic_cmds/tick
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

#****I* syscalls/team_cmds
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

#****iI* syscalls/team
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
#   team_declare teamname
#
# DESCRIPTION
#
#   The team_declare command sets the team alliance to the teamname
#   argument. team_declare is only effective the first time it is
#   executed in a robot control program. team_declare returns the
#   teamname value.
#
#   Cost: 1 tick.
#
#******

#****P* team_cmds/team_declare
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
#   team_send data
#
# DESCRIPTION
#
#   The team_send command makes the argument available to all other
#   robots with the same teamname. Data is a single string argument, and
#   can be any value or list. If a team has not been declared with the
#   team_declare command, the team_send command has no effect.
#
#   Cost: 0 ticks.
#
#******

#****P* team_cmds/team_send
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
#   The team_get command returns a list of team members and their
#   current data values. Each element of the list returned is a list of
#   the digital signature of a team member and that robot's last
#   team_send data value. If a team has not been declared with
#   team_declare or all of the other members of the team have not
#   declared a team or are dead, the return value is an null list. The
#   robot executing the team_get command is also excluded from the
#   return list.
#
#   Cost: 0 ticks.
#
#******

#****P* team_cmds/team_get
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

#****I* syscalls/convenience_cmds
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

#****iI* syscalls/convenience
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
#   dputs args
#
# DESCRIPTION
#
#   The dputs command prints a message in the GUI message window.
#   Dputs accepts any number of arguments.
#
#   Cost: 0 ticks.
#
#******

#****P* convenience_cmds/dputs
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
#   rand max
#
# DESCRIPTION
#
#   The rand command is a simple random number generator, based on
#   Knuth's algorithm. The rand command returns an integer between 0 and
#   ( max - 1), where max is in the range 1 to 65535. The seed value is
#   randomly set; if a particular seed value is desired, the global
#   variable _lastvalue should be set to some starting value.
#
#   Cost: 0 ticks.
#
#******

#****P* convenience_cmds/rand
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
#   callback time script
#
# DESCRIPTION
#
#   Cost: 0 ticks.
#
#******

#****P* convenience_cmds/callback
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

#****I* syscalls/deprecated_cmds
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

#****P* deprecated_cmds/after
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

#****P* deprecated_cmds/damage
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
