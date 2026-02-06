#!/usr/bin/env bats

# Test helper - loads the library and sets up common variables
setup() {
    # Get the test directory
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    
    # Source the library
    source "$PROJECT_ROOT/lib/cfmon.sh"
    
    # Set test mode (prevents actual AWS calls)
    export CFMON_AWS_CMD="mock-aws"
    export CFMON_LOG_LEVEL="DEBUG"
}

# Helper to create mock AWS CLI
create_mock_aws() {
    local fixture_file="$1"
    
    # Create a mock aws command that returns fixture data
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/mock-aws" << EOF
#!/bin/bash
if [[ "\$*" == *"describe-stack-events"* ]]; then
    cat "$fixture_file"
    exit 0
else
    echo "Unknown command: \$*" >&2
    exit 1
fi
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/mock-aws"
    
    # Add to PATH
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}
