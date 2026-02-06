#!/usr/bin/env bats

load test_helper

# Test validate_polling_interval
@test "validate_polling_interval accepts positive integer" {
    run validate_polling_interval "15"
    [ "$status" -eq 0 ]
}

@test "validate_polling_interval rejects zero" {
    run validate_polling_interval "0"
    [ "$status" -eq 1 ]
    [[ "$output" == *"positive integer"* ]]
}

@test "validate_polling_interval rejects negative number" {
    run validate_polling_interval "-5"
    [ "$status" -eq 1 ]
}

@test "validate_polling_interval rejects non-numeric" {
    run validate_polling_interval "abc"
    [ "$status" -eq 1 ]
}

# Test validate_max_runtime
@test "validate_max_runtime accepts zero" {
    run validate_max_runtime "0"
    [ "$status" -eq 0 ]
}

@test "validate_max_runtime accepts positive integer" {
    run validate_max_runtime "300"
    [ "$status" -eq 0 ]
}

@test "validate_max_runtime rejects negative number" {
    run validate_max_runtime "-1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"non-negative"* ]]
}

# Test is_terminal_state
@test "is_terminal_state returns true for CREATE_COMPLETE" {
    run is_terminal_state "CREATE_COMPLETE"
    [ "$status" -eq 0 ]
}

@test "is_terminal_state returns true for UPDATE_COMPLETE" {
    run is_terminal_state "UPDATE_COMPLETE"
    [ "$status" -eq 0 ]
}

@test "is_terminal_state returns true for CREATE_FAILED" {
    run is_terminal_state "CREATE_FAILED"
    [ "$status" -eq 0 ]
}

@test "is_terminal_state returns false for CREATE_IN_PROGRESS" {
    run is_terminal_state "CREATE_IN_PROGRESS"
    [ "$status" -eq 1 ]
}

@test "is_terminal_state returns false for UPDATE_IN_PROGRESS" {
    run is_terminal_state "UPDATE_IN_PROGRESS"
    [ "$status" -eq 1 ]
}

# Test is_success_state
@test "is_success_state returns true for CREATE_COMPLETE" {
    run is_success_state "CREATE_COMPLETE"
    [ "$status" -eq 0 ]
}

@test "is_success_state returns true for DELETE_COMPLETE" {
    run is_success_state "DELETE_COMPLETE"
    [ "$status" -eq 0 ]
}

@test "is_success_state returns false for ROLLBACK_COMPLETE" {
    run is_success_state "ROLLBACK_COMPLETE"
    [ "$status" -eq 1 ]
}

@test "is_success_state returns false for CREATE_FAILED" {
    run is_success_state "CREATE_FAILED"
    [ "$status" -eq 1 ]
}

# Test is_failure_state
@test "is_failure_state returns true for CREATE_FAILED" {
    run is_failure_state "CREATE_FAILED"
    [ "$status" -eq 0 ]
}

@test "is_failure_state returns true for ROLLBACK_COMPLETE" {
    run is_failure_state "ROLLBACK_COMPLETE"
    [ "$status" -eq 0 ]
}

@test "is_failure_state returns false for CREATE_COMPLETE" {
    run is_failure_state "CREATE_COMPLETE"
    [ "$status" -eq 1 ]
}

# Test calculate_sleep_time
@test "calculate_sleep_time returns polling interval when no max runtime" {
    result=$(calculate_sleep_time "15" "0" "1000" "1010")
    [ "$result" -eq 15 ]
}

@test "calculate_sleep_time returns remaining time when close to limit" {
    # max_runtime=60, start=1000, current=1055, so remaining=5
    result=$(calculate_sleep_time "15" "60" "1000" "1055")
    [ "$result" -eq 5 ]
}

@test "calculate_sleep_time returns polling interval when plenty of time" {
    # max_runtime=60, start=1000, current=1020, so elapsed=20, plenty of time
    result=$(calculate_sleep_time "15" "60" "1000" "1020")
    [ "$result" -eq 15 ]
}

# Test check_runtime_exceeded
@test "check_runtime_exceeded returns false when no limit" {
    run check_runtime_exceeded "0" "1000" "2000"
    [ "$status" -eq 1 ]
}

@test "check_runtime_exceeded returns false when under limit" {
    # limit=60, start=1000, current=1050 (50 seconds elapsed)
    run check_runtime_exceeded "60" "1000" "1050"
    [ "$status" -eq 1 ]
}

@test "check_runtime_exceeded returns true when at limit" {
    # limit=60, start=1000, current=1060 (60 seconds elapsed)
    run check_runtime_exceeded "60" "1000" "1060"
    [ "$status" -eq 0 ]
}

@test "check_runtime_exceeded returns true when over limit" {
    # limit=60, start=1000, current=1065 (65 seconds elapsed)
    run check_runtime_exceeded "60" "1000" "1065"
    [ "$status" -eq 0 ]
}

# Test filter_new_events with colorization
@test "filter_new_events returns properly formatted events with colorization" {
    # Mock events JSON with a single event
    local events_json='[
        {
            "Timestamp": "2023-01-01T12:00:00.000Z",
            "ResourceStatus": "CREATE_IN_PROGRESS",
            "ResourceType": "AWS::EC2::Instance",
            "LogicalResourceId": "MyInstance"
        }
    ]'
    
    run filter_new_events "$events_json" "2023-01-01T11:00:00.000Z"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CREATE_IN_PROGRESS" ]]  # Check that the status is present
    [[ "$output" =~ "AWS::EC2::Instance" ]]  # Check that the resource type is present
    [[ "$output" =~ "MyInstance" ]]          # Check that the logical ID is present
    # Check that ANSI color codes are present (indicating colorization occurred)
    [[ "$output" =~ $'\033' ]]               # Check for ANSI escape sequence
}

@test "filter_new_events handles multiple events" {
    local events_json='[
        {
            "Timestamp": "2023-01-01T12:00:01.000Z",
            "ResourceStatus": "CREATE_IN_PROGRESS",
            "ResourceType": "AWS::EC2::Instance",
            "LogicalResourceId": "MyInstance"
        },
        {
            "Timestamp": "2023-01-01T12:00:02.000Z",
            "ResourceStatus": "CREATE_COMPLETE",
            "ResourceType": "AWS::EC2::Instance",
            "LogicalResourceId": "MyInstance"
        }
    ]'
    
    run filter_new_events "$events_json" "2023-01-01T11:00:00.000Z"
    
    [ "$status" -eq 0 ]
    # Should have 2 lines of output
    local line_count
    line_count=$(echo "$output" | wc -l)
    [ "$line_count" -ge 2 ]
    # Check that ANSI color codes are present (indicating colorization occurred)
    [[ "$output" =~ $'\033' ]]               # Check for ANSI escape sequence
}
