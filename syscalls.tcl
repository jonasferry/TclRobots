### Basic commands
## 2 ticks
#scanner degree resolution
proc scanner {degree resolution} {
    syscall scanner $degree $resolution
    yield
    syscall scanner $degree $resolution
    yield
}
## 1 tick
#dsp
proc dsp {} {
    syscall dsp
    yield
}
#alert proc-name
proc alert {procname} {
    syscall alert $procname
    yield
}
#cannon degree range
proc cannon {degree range} {
    syscall cannon $degree $range
    yield
}
#damage
proc damage {} {
    syscall damage
    yield
}
#drive degree speed
proc drive {degree speed} {
    syscall drive $degree $speed
    yield
}
#speed
proc speed {} {
    syscall speed
    yield
}
#heat
proc heat {} {
    syscall heat
    yield
}
#loc_x
proc loc_x {} {
    syscall loc_x
    yield
}
#loc_y
proc loc_y {} {
    syscall loc_y
    yield
}
#tick
proc tick {} {
    syscall tick
    yield
}

## Team commands
# 1 tick
#team_declare teamname
proc team_declare {teamname} {
    syscall team_declare $teamname
    yield
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
