# Check the answer from a yield for a ping alert
proc _ping_check {val} {
    if {[lindex $val 0] eq "alert"} {
        #  ping_proc:        dsp:
        [lindex $val 1] [lindex $val 2]
        set val [lrange $val 3 end]
    }
    return $val
}

# Combine the common syscall+yield call
proc _syscall_yield {args} {
    set result [syscall callbackcheck]
    if {$result ne ""} {
        uplevel \#0 $result
    }
    syscall {*}$args
    return [_ping_check [yield]]
}


### Basic commands
## 2 ticks
#scanner degree resolution
proc scanner {degree resolution} {
    _syscall_yield scanner $degree $resolution
    _syscall_yield scanner $degree $resolution
}
## 1 tick
#dsp
proc dsp {} {
    _syscall_yield dsp
}
#alert proc-name
proc alert {procname} {
    _syscall_yield alert $procname
}
#cannon degree range
proc cannon {degree range} {
    _syscall_yield cannon $degree $range
}
#health
proc health {} {
    _syscall_yield health
}
#drive degree speed
proc drive {degree speed} {
    _syscall_yield drive $degree $speed
}
#speed
proc speed {} {
    _syscall_yield speed
}
#heat
proc heat {} {
    _syscall_yield heat
}
#loc_x
proc loc_x {} {
    _syscall_yield loc_x
}
#loc_y
proc loc_y {} {
    _syscall_yield loc_y
}
#tick
proc tick {} {
    _syscall_yield tick
}

## Team commands
# 1 tick
#team_declare teamname
proc team_declare {teamname} {
    _syscall_yield team_declare $teamname
}
# 0 ticks
#team_send data
proc team_send {data} {
    syscall team_send $data
}
#team_get
proc team_get {} {
    syscall team_get
}

## Convenience commands
# 0 ticks
#dputs args
proc dputs {args} {
    syscall dputs $args
}
#rand max
proc rand {max} {
    syscall rand $max
}

proc callback {time script} {
    syscall callback $time $script
}

# After does not work, emulate it using callbacks
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
