#!/bin/bash
#
# cfmon library - Core functions for CloudFormation monitoring
# This file contains all testable functions extracted from the main script
#

# Source the colors module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Global configuration (can be overridden for testing)
CFMON_AWS_CMD="${CFMON_AWS_CMD:-aws}"
CFMON_LOG_LEVEL="${CFMON_LOG_LEVEL:-INFO}"

# Function to handle termination signals
cleanup() {
    echo ""
    echo "Received termination signal. Exiting gracefully..."
    exit 0
}

# Function to check if AWS CLI is available
check_aws_cli() {
    if ! command -v "$CFMON_AWS_CMD" &> /dev/null; then
        echo "Error: AWS CLI is not installed. Please install it before running this script." >&2
        return 1
    fi
    return 0
}

# Function to check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it before running this script." >&2
        return 1
    fi
    return 0
}

# Function to validate polling interval
validate_polling_interval() {
    local interval="$1"
    if ! [[ "$interval" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Polling interval must be a positive integer (seconds)." >&2
        return 1
    fi
    return 0
}

# Function to validate max runtime
validate_max_runtime() {
    local runtime="$1"
    if ! [[ "$runtime" =~ ^[0-9]+$ ]]; then
        echo "Error: Max runtime must be a non-negative integer (seconds)." >&2
        return 1
    fi
    return 0
}

# Function to get initial timestamp (30 seconds ago)
# Cross-platform: macOS (BSD) vs Linux (GNU)
get_initial_timestamp() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS (BSD) date command
        date -v-30S -u +"%Y-%m-%dT%H:%M:%SZ"
    else
        # Linux (GNU) date command
        date -u -d "30 seconds ago" +"%Y-%m-%dT%H:%M:%SZ"
    fi
}

# Function to log messages conditionally based on log level
log_message() {
    local level="$1"
    shift
    local message="$*"

    case "$level" in
        DEBUG)
            if [[ "$CFMON_LOG_LEVEL" == "DEBUG" ]]; then
                echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message" >&2
            fi
            ;;
        *)
            echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $message" >&2
            ;;
    esac
}

# Function to check if a stack status is terminal (completed, failed, or rolled back)
is_terminal_state() {
    local status="$1"
    case "$status" in
        CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE|ROLLBACK_COMPLETE|UPDATE_ROLLBACK_COMPLETE)
            return 0
            ;;
        CREATE_FAILED|DELETE_FAILED|UPDATE_FAILED|ROLLBACK_FAILED|UPDATE_ROLLBACK_FAILED)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if a status is a success state
is_success_state() {
    local status="$1"
    case "$status" in
        CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if a status is a failure state
is_failure_state() {
    local status="$1"
    case "$status" in
        CREATE_FAILED|DELETE_FAILED|UPDATE_FAILED|ROLLBACK_FAILED|UPDATE_ROLLBACK_FAILED|ROLLBACK_COMPLETE|UPDATE_ROLLBACK_COMPLETE)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to fetch CloudFormation stack events
# Uses CFMON_AWS_CMD for testability (allows mocking)
fetch_stack_events() {
    local stack_name="$1"
    local output
    
    output=$("$CFMON_AWS_CMD" cloudformation describe-stack-events \
        --stack-name "$stack_name" \
        --query "StackEvents" \
        --output json 2>&1)
    
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo "Error: AWS CLI command failed" >&2
        echo "$output" >&2
        return 1
    fi
    
    echo "$output"
}

# Function to validate JSON
validate_json() {
    local json="$1"
    if [ -z "$json" ]; then
        return 1
    fi
    echo "$json" | jq -e . > /dev/null 2>&1
}

# Function to filter new events from the event list
filter_new_events() {
    local events_json="$1"
    local last_time="$2"

    # Extract events and format them with colors
    local formatted_events
    formatted_events=$(echo "$events_json" | jq -r --arg last_time "$last_time" '
        [ .[] | select(.Timestamp > $last_time) ] | reverse | .[] |
        "\(.ResourceStatus)|\(.Timestamp)|\(.ResourceType)|\(.LogicalResourceId)"
    ')

    # Process each event to add color
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            # Split the line by delimiter
            IFS='|' read -r status timestamp resource_type logical_id <<< "$line"
            
            # Get the colorized status
            local colorized_status
            colorized_status=$(colorize_status "$status")
            
            # Format the output with colorized status
            printf "[%s] %s - %s (%s)\n" "$timestamp" "$colorized_status" "$resource_type" "$logical_id"
        fi
    done <<< "$formatted_events"
}

# Function to get the latest timestamp from events
get_latest_timestamp() {
    local events_json="$1"
    echo "$events_json" | jq -r '.[0].Timestamp'
}

# Function to get the stack status from events
get_stack_status() {
    local events_json="$1"
    local stack_name="$2"
    
    echo "$events_json" | jq -r \
        '.[] | select(.ResourceType == "AWS::CloudFormation::Stack" and .LogicalResourceId == "'"$stack_name"'") | .ResourceStatus' | \
        head -1
}

# Function to calculate sleep time considering max runtime
calculate_sleep_time() {
    local polling_interval="$1"
    local max_runtime="$2"
    local start_time="$3"
    local current_time="$4"

    if [ "$max_runtime" -gt 0 ]; then
        local elapsed_time=$((current_time - start_time))
        local remaining_time=$((max_runtime - elapsed_time))

        if [ "$remaining_time" -lt "$polling_interval" ]; then
            echo "$remaining_time"
        else
            echo "$polling_interval"
        fi
    else
        echo "$polling_interval"
    fi
}

# Function to count different statuses in events
count_statuses() {
    local events_json="$1"
    
    # Count different status types using regex matching
    local create_in_progress
    create_in_progress=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus | test("^CREATE_IN_PROGRESS"))] | length')
    local create_complete
    create_complete=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus == "CREATE_COMPLETE")] | length')
    local update_in_progress
    update_in_progress=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus | test("^UPDATE_IN_PROGRESS"))] | length')
    local update_complete
    update_complete=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus == "UPDATE_COMPLETE")] | length')
    local delete_in_progress
    delete_in_progress=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus | test("^DELETE_IN_PROGRESS"))] | length')
    local delete_complete
    delete_complete=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus == "DELETE_COMPLETE")] | length')
    local failed
    failed=$(echo "$events_json" | jq -r '[.[] | select(.ResourceStatus | test("_FAILED$|_ROLLBACK_COMPLETE$"))] | length')
    
    echo "$create_in_progress $create_complete $update_in_progress $update_complete $delete_in_progress $delete_complete $failed"
}

# Function to check if runtime limit exceeded
check_runtime_exceeded() {
    local max_runtime="$1"
    local start_time="$2"
    local current_time="$3"
    
    if [ "$max_runtime" -gt 0 ]; then
        local elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "$max_runtime" ]; then
            return 0
        fi
    fi
    return 1
}
