# cfmon - CloudFormation Monitor

A real-time monitoring tool for AWS CloudFormation stack events. Provides live visibility into stack updates, deployments, and changes as they happen.

## Overview

`cfmon` polls CloudFormation stack events in near real-time, displaying resource status changes, types, and logical IDs as they occur during deployments. This provides visibility similar to the AWS Console's Events tab, but in your terminal during automated deployments.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions
- `jq` for JSON processing
- Bash-compatible shell

## Usage

```bash
./cfmon <stack-name> [polling-interval] [max-runtime] [log-level]
```

### Arguments

- `<stack-name>`: Name of the CloudFormation stack to monitor (required)
- `[polling-interval]`: Polling interval in seconds (optional, default: 15)
- `[max-runtime]`: Maximum runtime in seconds (optional, default: 0 for no limit)
- `[log-level]`: Log level (optional, default: INFO, options: INFO, DEBUG)

### Examples

Monitor a stack with default settings:
```bash
./cfmon my-production-stack
```

Monitor with custom polling interval (10 seconds):
```bash
./cfmon my-production-stack 10
```

Monitor for maximum 300 seconds (5 minutes):
```bash
./cfmon my-production-stack 15 300
```

Monitor with debug logging:
```bash
./cfmon my-production-stack 15 0 DEBUG
```

## Features

- Real-time event monitoring during stack updates
- Cross-platform compatibility (macOS and Linux)
- Graceful shutdown handling (Ctrl+C)
- Configurable polling intervals
- Optional runtime limits
- Multiple log levels for debugging
- Proper error handling for AWS API calls