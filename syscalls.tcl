proc ping_check {val} {
    if {[lindex $val 0] eq "alert"} {
        #  ping_proc:        dsp:
        [lindex $val 1] [lindex $val 2]
        set val [lrange $val 3 end]
    }
    return $val
}

### Basic commands
## 2 ticks
#scanner degree resolution
proc scanner {degree resolution} {
    syscall scanner $degree $resolution
    ping_check [yield]
    syscall scanner $degree $resolution
    return [ping_check [yield]]
}
## 1 tick
#dsp
proc dsp {} {
    syscall dsp
    return [ping_check [yield]]
}
#alert proc-name
proc alert {procname} {
    syscall alert $procname
    return [ping_check [yield]]
}
#cannon degree range
proc cannon {degree range} {
    syscall cannon $degree $range
    return [ping_check [yield]]
}
#health
proc health {} {
    syscall health
    return [ping_check [yield]]
}
#drive degree speed
proc drive {degree speed} {
    syscall drive $degree $speed
    return [ping_check [yield]]
}
#speed
proc speed {} {
    syscall speed
    return [ping_check [yield]]
}
#heat
proc heat {} {
    syscall heat
    return [ping_check [yield]]
}
#loc_x
proc loc_x {} {
    syscall loc_x
    return [ping_check [yield]]
}
#loc_y
proc loc_y {} {
    syscall loc_y
    return [ping_check [yield]]
}
#tick
proc tick {} {
    syscall tick
    return [ping_check [yield]]
}

## Team commands
# 1 tick
#team_declare teamname
proc team_declare {teamname} {
    syscall team_declare $teamname
    return [ping_check [yield]]
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
