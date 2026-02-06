#!/usr/bin/env bats
#
# Tests for the colors module functionality
#

load './test_helper'

# Setup function - load the colors module directly
setup() {
    load '../lib/colors.sh'
}

@test "colorize_status returns green for success states" {
    run colorize_status "CREATE_COMPLETE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;32m'CREATE_COMPLETE$'\033[0m' ]]
    
    run colorize_status "UPDATE_COMPLETE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;32m'UPDATE_COMPLETE$'\033[0m' ]]
    
    run colorize_status "DELETE_COMPLETE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;32m'DELETE_COMPLETE$'\033[0m' ]]
}

@test "colorize_status returns yellow for progress states" {
    run colorize_status "CREATE_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[1;33m'CREATE_IN_PROGRESS$'\033[0m' ]]
    
    run colorize_status "UPDATE_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[1;33m'UPDATE_IN_PROGRESS$'\033[0m' ]]
    
    run colorize_status "DELETE_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[1;33m'DELETE_IN_PROGRESS$'\033[0m' ]]
    
    run colorize_status "UPDATE_ROLLBACK_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[1;33m'UPDATE_ROLLBACK_IN_PROGRESS$'\033[0m' ]]
}

@test "colorize_status returns red for failure states" {
    run colorize_status "CREATE_FAILED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'CREATE_FAILED$'\033[0m' ]]
    
    run colorize_status "UPDATE_FAILED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'UPDATE_FAILED$'\033[0m' ]]
    
    run colorize_status "DELETE_FAILED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'DELETE_FAILED$'\033[0m' ]]
    
    run colorize_status "ROLLBACK_FAILED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'ROLLBACK_FAILED$'\033[0m' ]]
    
    run colorize_status "UPDATE_ROLLBACK_FAILED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'UPDATE_ROLLBACK_FAILED$'\033[0m' ]]
    
    run colorize_status "ROLLBACK_COMPLETE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'ROLLBACK_COMPLETE$'\033[0m' ]]
    
    run colorize_status "UPDATE_ROLLBACK_COMPLETE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;31m'UPDATE_ROLLBACK_COMPLETE$'\033[0m' ]]
}

@test "colorize_status returns blue for warning states" {
    run colorize_status "ROLLBACK_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;34m'ROLLBACK_IN_PROGRESS$'\033[0m' ]]
    
    run colorize_status "IMPORT_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;34m'IMPORT_IN_PROGRESS$'\033[0m' ]]
    
    run colorize_status "IMPORT_ROLLBACK_IN_PROGRESS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;34m'IMPORT_ROLLBACK_IN_PROGRESS$'\033[0m' ]]
    
    run colorize_status "IMPORT_ROLLBACK_FAILED"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[0;34m'IMPORT_ROLLBACK_FAILED$'\033[0m' ]]
}

@test "colorize_status returns white for default cases" {
    run colorize_status "UNKNOWN_STATUS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[1;37m'UNKNOWN_STATUS$'\033[0m' ]]
}

@test "colorize_status handles empty input" {
    run colorize_status ""
    [ "$status" -eq 0 ]
    [[ "$output" =~ $'\033[1;37m'$'\033[0m' ]]  # Should return white with no text
}