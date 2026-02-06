#!/usr/bin/env bats

load test_helper

# Test validate_json
@test "validate_json returns true for valid JSON" {
    run validate_json '{"key": "value"}'
    [ "$status" -eq 0 ]
}

@test "validate_json returns false for invalid JSON" {
    run validate_json '{invalid json'
    [ "$status" -ne 0 ]
}

@test "validate_json handles empty string" {
    run validate_json ''
    [ "$status" -eq 1 ]
}

# Test get_latest_timestamp
@test "get_latest_timestamp extracts timestamp from events" {
    local fixture="$PROJECT_ROOT/tests/fixtures/create-complete.json"
    result=$(get_latest_timestamp "$(cat "$fixture")")
    [ "$result" = "2024-01-15T10:00:00.000Z" ]
}

@test "get_latest_timestamp returns null for empty array" {
    result=$(get_latest_timestamp '[]')
    [ "$result" = "null" ]
}

# Test get_stack_status
@test "get_stack_status extracts CREATE_COMPLETE status" {
    local fixture="$PROJECT_ROOT/tests/fixtures/create-complete.json"
    result=$(get_stack_status "$(cat "$fixture")" "my-stack")
    [ "$result" = "CREATE_COMPLETE" ]
}

@test "get_stack_status returns empty for non-matching stack" {
    local fixture="$PROJECT_ROOT/tests/fixtures/create-complete.json"
    result=$(get_stack_status "$(cat "$fixture")" "wrong-stack")
    [ -z "$result" ]
}

# Test filter_new_events
@test "filter_new_events filters events after timestamp" {
    local fixture="$PROJECT_ROOT/tests/fixtures/create-complete.json"
    # All events are after 2024-01-15T09:00:00Z
    result=$(filter_new_events "$(cat "$fixture")" "2024-01-15T09:00:00Z")
    [ -n "$result" ]
    [[ "$result" == *"CREATE_COMPLETE"* ]]
}

@test "filter_new_events returns empty when no new events" {
    local fixture="$PROJECT_ROOT/tests/fixtures/create-complete.json"
    # All events are before 2025-01-15T10:00:00Z
    result=$(filter_new_events "$(cat "$fixture")" "2025-01-15T10:00:00Z")
    [ -z "$result" ]
}
