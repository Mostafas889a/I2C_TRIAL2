#!/bin/bash

# Setup environment for caravel-cocotb testing
export USER_PROJECT_ROOT=/workspace/I2C_TRIAL2
export PDK_ROOT=${PDK_ROOT:-/nc/apps/pdk}
export PDK=${PDK:-sky130A}
export CARAVEL_ROOT=${CARAVEL_ROOT:-/nc/templates/caravel}
export MCW_ROOT=${MCW_ROOT:-/nc/templates/mgmt_core_wrapper}

echo "========================================"
echo "I2C Caravel User Project Test Runner"
echo "========================================"
echo "USER_PROJECT_ROOT: $USER_PROJECT_ROOT"
echo "PDK_ROOT: $PDK_ROOT"
echo "PDK: $PDK"
echo "CARAVEL_ROOT: $CARAVEL_ROOT"
echo "MCW_ROOT: $MCW_ROOT"
echo "========================================"

# Check if test name is provided
if [ -z "$1" ]; then
    echo "Usage: ./run_test.sh <test_name>"
    echo "Example: ./run_test.sh i2c_test"
    echo ""
    echo "Available tests:"
    ls -1 $USER_PROJECT_ROOT/verilog/dv/cocotb/ 2>/dev/null | grep -v "^sim$" | grep -v "\.py$" | grep -v "\.yaml$" | grep -v "\.gitignore$"
    exit 1
fi

TEST_NAME=$1

# Run from cocotb directory
COCOTB_DIR=$USER_PROJECT_ROOT/verilog/dv/cocotb
cd $COCOTB_DIR

# Check if design_info.yaml exists
if [ ! -f "design_info.yaml" ]; then
    echo "Error: design_info.yaml not found in $COCOTB_DIR"
    exit 1
fi

echo "Running test: $TEST_NAME"
echo "Working directory: $COCOTB_DIR"
echo ""

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
    echo "Simulation files: $COCOTB_DIR/sim/$TEST_NAME/"
    echo "Waveform: $COCOTB_DIR/sim/$TEST_NAME/${TEST_NAME}.vcd"
    echo "Log: $COCOTB_DIR/sim/$TEST_NAME/${TEST_NAME}.log"
else
    echo ""
    echo "========================================"
    echo "Test failed with errors"
    echo "========================================"
    echo "Check logs in: $COCOTB_DIR/sim/$TEST_NAME/"
    exit 1
fi
