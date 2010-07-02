#!/usr/bin/env tclsh

package require tcltest
namespace import ::tcltest::*

set ::testDir [file dirname [file normalize [info script]]]
puts "testDir $::testDir"

configure -testdir $::testDir
eval configure $argv
runAllTests