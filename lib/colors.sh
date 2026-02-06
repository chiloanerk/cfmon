#!/bin/bash
#
# cfmon colors module - Functions for colorizing output
#

# Color codes
readonly CFMON_COLOR_RED='\033[0;31m'
readonly CFMON_COLOR_GREEN='\033[0;32m'
readonly CFMON_COLOR_YELLOW='\033[1;33m'
readonly CFMON_COLOR_BLUE='\033[0;34m'
readonly CFMON_COLOR_PURPLE='\033[0;35m'
readonly CFMON_COLOR_CYAN='\033[0;36m'
readonly CFMON_COLOR_WHITE='\033[1;37m'
readonly CFMON_COLOR_NC='\033[0m' # No Color

# Function to colorize resource status
colorize_status() {
    local status="$1"
    
    case "$status" in
        # Success states - Green
        CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE)
            echo -e "${CFMON_COLOR_GREEN}${status}${CFMON_COLOR_NC}"
            ;;
        # Progress states - Yellow
        CREATE_IN_PROGRESS|UPDATE_IN_PROGRESS|DELETE_IN_PROGRESS|UPDATE_ROLLBACK_IN_PROGRESS)
            echo -e "${CFMON_COLOR_YELLOW}${status}${CFMON_COLOR_NC}"
            ;;
        # Failure states - Red
        CREATE_FAILED|UPDATE_FAILED|DELETE_FAILED|ROLLBACK_FAILED|UPDATE_ROLLBACK_FAILED|ROLLBACK_COMPLETE|UPDATE_ROLLBACK_COMPLETE)
            echo -e "${CFMON_COLOR_RED}${status}${CFMON_COLOR_NC}"
            ;;
        # Warning states - Blue
        ROLLBACK_IN_PROGRESS|IMPORT_IN_PROGRESS|IMPORT_ROLLBACK_IN_PROGRESS|IMPORT_ROLLBACK_FAILED)
            echo -e "${CFMON_COLOR_BLUE}${status}${CFMON_COLOR_NC}"
            ;;
        # Default - White
        *)
            echo -e "${CFMON_COLOR_WHITE}${status}${CFMON_COLOR_NC}"
            ;;
    esac
}

# Function to colorize resource types (optional enhancement)
colorize_resource_type() {
    local resource_type="$1"
    echo -e "${CFMON_COLOR_CYAN}${resource_type}${CFMON_COLOR_NC}"
}

# Function to colorize timestamps (optional enhancement)
colorize_timestamp() {
    local timestamp="$1"
    echo -e "${CFMON_COLOR_WHITE}${timestamp}${CFMON_COLOR_NC}"
}