#!/bin/bash

# Setup environment for caravel-cocotb testing
export USER_PROJECT_ROOT=/workspace/I2C_TRIAL2
export PDK_ROOT=${PDK_ROOT:-/usr/local/share/pdk}
export PDK=${PDK:-sky130A}

echo "========================================"
echo "I2C Caravel User Project Test Runner"
echo "========================================"
echo "USER_PROJECT_ROOT: $USER_PROJECT_ROOT"
echo "PDK_ROOT: $PDK_ROOT"
echo "PDK: $PDK"
echo "========================================"

# Check if test name is provided
if [ -z "$1" ]; then
    echo "Usage: ./run_test.sh <test_name>"
    echo "Example: ./run_test.sh i2c_test"
    exit 1
fi

TEST_NAME=$1
TEST_DIR=$USER_PROJECT_ROOT/verilog/dv/cocotb/$TEST_NAME

# Check if test directory exists
if [ ! -d "$TEST_DIR" ]; then
    echo "Error: Test directory not found: $TEST_DIR"
    echo "Available tests:"
    ls -1 $USER_PROJECT_ROOT/verilog/dv/cocotb/ 2>/dev/null | grep -v "^sim$"
    exit 1
fi

echo "Running test: $TEST_NAME"
echo "Test directory: $TEST_DIR"
echo ""

# Change to test directory and run
cd $TEST_DIR

# Check if design_info.yaml exists
if [ ! -f "design_info.yaml" ]; then
    echo "Error: design_info.yaml not found in $TEST_DIR"
    exit 1
fi

# Run the test
echo "Executing: caravel_cocotb -t $TEST_NAME -d design_info.yaml"
echo ""
caravel_cocotb -t $TEST_NAME -d design_info.yaml

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Test completed successfully!"
    echo "========================================"
    echo "Simulation files: $TEST_DIR/sim/$TEST_NAME/"
    echo "Waveform: $TEST_DIR/sim/$TEST_NAME/${TEST_NAME}.vcd"
    echo "Log: $TEST_DIR/sim/$TEST_NAME/${TEST_NAME}.log"
else
    echo ""
    echo "========================================"
    echo "Test failed with errors"
    echo "========================================"
    echo "Check logs in: $TEST_DIR/sim/$TEST_NAME/"
    exit 1
fi
