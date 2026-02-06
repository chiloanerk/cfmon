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
  * Green for success states (CREATE_COMPLETE, UPDATE_COMPLETE, etc.)
  * Yellow for progress states (CREATE_IN_PROGRESS, etc.)
  * Red for failure states (CREATE_FAILED, etc.)
  * Blue for warning states (ROLLBACK_IN_PROGRESS, etc.)
