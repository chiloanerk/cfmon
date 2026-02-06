# cfmon - CloudFormation Monitor

A real-time monitoring tool for AWS CloudFormation stack events. Provides
live visibility into stack updates, deployments, and changes as they happen.

## Overview

`cfmon` polls CloudFormation stack events in near real-time, displaying
resource status changes, types, and logical IDs as they occur during
deployments. This provides visibility similar to the AWS Console's Events tab,
but in your terminal during automated deployments.

## Installation

### Quick Install (macOS/Linux)

```bash
# Clone the repository
git clone https://github.com/chiloanerk/cfmon.git
cd cfmon

# Make executable
chmod +x cfmon

# Optional: Add to PATH
sudo ln -s "$(pwd)/cfmon" /usr/local/bin/cfmon
```

### Prerequisites

**Required:**

- AWS CLI installed and configured with appropriate permissions
- `jq` for JSON processing
- Bash-compatible shell (bash 4.0+)

**For Development:**

- [Bats](https://github.com/bats-core/bats-core) - Bash Automated Testing System
- ShellCheck (for linting)

## Project Structure

```text
.
├── cfmon                    # Backward compatibility wrapper
├── bin/
│   └── cfmon               # Main executable script
├── lib/
│   ├── cfmon.sh            # Library with core functions (testable)
│   └── colors.sh           # Module for colorizing output
├── tests/
│   ├── test_helper.bash    # Test utilities and setup
│   ├── unit_functions.bats # Unit tests for individual functions
│   ├── unit_colors.bats    # Unit tests for colorization functions
│   ├── integration_data.bats # Integration tests for data processing
│   └── fixtures/           # Test data files
└── .github/
    └── workflows/
        └── tests.yml       # CI/CD pipeline
```

## Development

### Running Tests Locally

Install Bats:

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats
```

Run all tests:

```bash
bats tests/
```

Run specific test file:

```bash
bats tests/unit_functions.bats
```

Run with TAP output:

```bash
bats --tap tests/
```

### Testing with Mocks

The test framework supports mocking AWS CLI calls by setting `CFMON_AWS_CMD`
environment variable:

```bash
# Create a mock aws command
export CFMON_AWS_CMD="/path/to/mock-aws"

# Or point to a fixture file
export CFMON_AWS_CMD="cat tests/fixtures/create-complete.json"
```

### Code Quality

Run ShellCheck:

```bash
shellcheck lib/cfmon.sh bin/cfmon
```

## CI/CD

This project uses GitHub Actions for continuous integration. The workflow:

- Runs all Bats tests on every push and PR
- Performs ShellCheck linting
- Validates markdown files

## Environment Variables

- `CFMON_AWS_CMD`: Override the AWS CLI command (default: `aws`)
- `CFMON_LOG_LEVEL`: Set log level (default: `INFO`, options: `INFO`, `DEBUG`)

## Usage

```bash
./cfmon <stack-name> [polling-interval] [max-runtime] [log-level]
```

### Arguments

- `<stack-name>`: Name of the CloudFormation stack to monitor (required)
- `[polling-interval]`: Polling interval in seconds (optional, default: 15)
- `[max-runtime]`: Maximum runtime in seconds (optional, default: 0 for no
  limit)
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
- Colorized status display for enhanced readability:
  - Green for success states (CREATE_COMPLETE, UPDATE_COMPLETE, etc.)
  - Yellow for progress states (CREATE_IN_PROGRESS, etc.)
  - Red for failure states (CREATE_FAILED, etc.)
  - Blue for warning states (ROLLBACK_IN_PROGRESS, etc.)
- Status summary bar showing counts of different resource states
- Column alignment for improved readability
- Relative timestamp formatting (e.g., '30s ago', '2m ago')
- Resource grouping by type with `--group-by-type` option
- Progress indicators with `--show-progress` option
- Resource hierarchy visualization with `--show-hierarchy` option

## Options

- `--group-by-type`: Group events by resource type for better organization
- `--show-hierarchy`: Show resource hierarchy visualization with tree-like structure
- `--show-progress`: Display progress indicator showing completion percentage

## Visual Enhancement Examples

### Status Summary Bar

Shows a summary of resource statuses at the top of the output:

```text
IN PROGRESS: C:2 U:1 D:0 | COMPLETE: C:5 U:2 D:0 | FAILED: 1
```

### Column Alignment

Improved layout with consistent column alignment:

```text
[1m 30s ago]    CREATE_IN_PROGRESS    AWS::EC2::Instance        (MyInstance)
[2m 15s ago]    CREATE_COMPLETE       AWS::S3::Bucket           (MyBucket)
```

### Relative Timestamps

Human-readable timestamps showing relative time:

```text
[30s ago]    CREATE_IN_PROGRESS    AWS::EC2::Instance    (MyInstance)
[2m 15s ago] CREATE_COMPLETE       AWS::S3::Bucket       (MyBucket)
```

### Resource Grouping

Group events by resource type using the `--group-by-type` option:

```text
=== AWS::EC2::Instance ===
[2m 15s ago]    CREATE_IN_PROGRESS    AWS::EC2::Instance    (WebServer)
[1m 30s ago]    CREATE_COMPLETE       AWS::EC2::Instance    (AppServer)

=== AWS::S3::Bucket ===
[3m 45s ago]    CREATE_IN_PROGRESS    AWS::S3::Bucket       (DataBucket)
```

### Progress Indicators

Visual progress bar using the `--show-progress` option:

```text
Progress: [#####-----] 50%
```

### Resource Hierarchy

Tree-like structure showing resource relationships using the `--show-hierarchy` option:

```text
├── AWS::CloudFormation::Stack
    ├── AWS::IAM::Role (InstanceRole)
    │   ├── AWS::EC2::Instance (WebServer)
    │   │   ├── AWS::S3::Bucket (WebData)
    │   │   └── AWS::RDS::DBInstance (WebDatabase)
    └── AWS::S3::Bucket (ConfigBucket)
```
