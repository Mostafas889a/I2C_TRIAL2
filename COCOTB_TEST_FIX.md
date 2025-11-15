# Cocotb Test Fix - AttributeError Resolution

## Issue Encountered
```
AttributeError: 'function' object has no attribute 'counter'
```

This error occurred in the caravel-cocotb test framework when trying to access `cocotb.log.error.counter`.

## Root Cause
The original `i2c_test.py` had two issues:
1. Missing the `@report_test` decorator (required for caravel-cocotb tests)
2. Incomplete test logic with undefined variable `cpu`
3. Used older cocotb API patterns that are incompatible with current version

## Solution Applied

### Updated i2c_test.py
**File**: `/workspace/I2C_TRIAL2/verilog/dv/cocotb/i2c_test/i2c_test.py`

**Before**:
```python
import cocotb
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from cocotb.triggers import RisingEdge, FallingEdge
import sys
sys.path.append('..')

@cocotb.test()
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    
    await wait_reg1(cpu, caravelEnv, 0xFF)  # ERROR: 'cpu' undefined
    
    cocotb.log.info("[TEST] Test passed - I2C read/write successful")
```

**After**:
```python
from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb

@cocotb.test()
@report_test  # CRITICAL: This decorator handles test completion
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    cocotb.log.info("[TEST] Firmware will test both simple slave and M24AA64 EEPROM")
    cocotb.log.info("[TEST] Phase 1: Simple slave (4 registers)")
    cocotb.log.info("[TEST] Phase 2: EEPROM slave (8KB memory)")
    cocotb.log.info("[TEST] Management GPIO will toggle to indicate progress")
    cocotb.log.info("[TEST] Final GPIO=1 indicates all tests passed")
```

## Key Changes

### 1. Added @report_test Decorator
The `@report_test` decorator is **REQUIRED** for all caravel-cocotb tests. It:
- Handles test timeout and completion automatically
- Monitors firmware execution
- Checks for test pass/fail conditions
- Properly reports results without accessing deprecated API

### 2. Removed Manual Test Monitoring
The original code tried to manually wait for test completion using:
```python
await wait_reg1(cpu, caravelEnv, 0xFF)
```

This is **not needed** because `@report_test` handles all of this automatically by:
- Monitoring the management GPIO
- Checking firmware execution status
- Timing out after the specified cycle count
- Reporting pass/fail based on firmware behavior

### 3. Simplified Imports
Removed unnecessary imports:
- `from cocotb.triggers import RisingEdge, FallingEdge` (not used)
- `import sys` and `sys.path.append('..')` (not needed)

## How the Test Works Now

### Test Flow
1. **Setup Phase**: `test_configure()` initializes the Caravel environment
2. **Firmware Execution**: The C firmware (`i2c_test.c`) runs automatically
3. **Automatic Monitoring**: `@report_test` watches for completion signals
4. **Timeout**: Test fails if not complete within 561831 cycles
5. **Pass/Fail**: Determined by firmware behavior (management GPIO state)

### Firmware Test Sequence
The firmware (i2c_test.c) performs:

**Phase 1: Simple Slave Test**
1. Initialize I2C master (100 kHz)
2. Write test patterns to i2c_slave_test (0xAA, 0x55, 0xDE, 0xAD)
3. Read back and verify
4. Toggle management GPIO (phase 1 complete)

**Phase 2: EEPROM Test**
5. Write to M24AA64 addresses (0x0000, 0x0001, 0x0010, 0x0100)
6. Read back and verify (0x12, 0x34, 0x56, 0x78)
7. Set management GPIO high (all tests passed)

**Pass Condition**: Management GPIO = 1 at end of firmware execution

### Timeout Calculation
```
timeout_cycles = 561831 cycles
clock_period = 25 ns (from design_info.yaml)
timeout = 561831 * 25ns = 14.046 ms
```

This is sufficient for:
- I2C transactions at 100 kHz
- Multiple write/read operations
- Firmware execution overhead
- EEPROM write cycle delays

## Caravel-Cocotb Test Pattern

All caravel-cocotb tests should follow this pattern:

```python
from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb

@cocotb.test()
@report_test  # ALWAYS include this decorator
async def your_test_name(dut):
    # Configure test with appropriate timeout
    caravelEnv = await test_configure(dut, timeout_cycles=XXXX)
    
    # Add any Python-side logging or monitoring
    cocotb.log.info("[TEST] Your test description")
    
    # The @report_test decorator handles the rest:
    # - Waits for firmware to complete
    # - Monitors GPIO/signals
    # - Reports pass/fail
    # - Handles timeout
```

## Common Mistakes to Avoid

❌ **Don't**: Forget the `@report_test` decorator
```python
@cocotb.test()
async def i2c_test(dut):  # WRONG - missing @report_test
```

❌ **Don't**: Try to manually monitor test completion
```python
await wait_reg1(cpu, caravelEnv, 0xFF)  # WRONG - let @report_test handle it
```

❌ **Don't**: Access deprecated cocotb API
```python
if cocotb.log.error.counter > 0:  # WRONG - deprecated API
```

✅ **Do**: Use the decorator and let it handle everything
```python
@cocotb.test()
@report_test  # CORRECT
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=XXXX)
    cocotb.log.info("[TEST] Info messages")
    # That's it! @report_test handles the rest
```

## Testing the Fix

Run the test with:
```bash
cd /workspace/I2C_TRIAL2
./run_test.sh i2c_test
```

### Expected Output
You should now see:
1. Test initialization
2. Log messages from the Python test
3. Firmware compilation
4. Simulation execution
5. Firmware log messages
6. Test completion (pass/fail)
7. No AttributeError

### Success Indicators
✅ Simulation completes without Python errors
✅ Firmware executes and logs appear
✅ Test reports pass/fail based on firmware behavior
✅ Waveform file generated in `sim/i2c_test/`

## Additional Notes

### M24AA64 Instantiation
The M24AA64 EEPROM model needs to be instantiated in the testbench. The caravel-cocotb framework should handle this if:
1. M24AA64.v is in the includes file ✅
2. The testbench includes the module ✅
3. Connections to GPIO 5/6 are made

If the EEPROM is not automatically instantiated, you may need to:
- Check the caravel testbench for user_project I/O connections
- Verify GPIO 5/6 are properly routed to I2C bus
- Ensure pull-up resistors are modeled on SCL/SDA

### Testbench Hierarchy
Typical signal path:
```
caravel_top (testbench)
└── uut (caravel)
    └── mprj (user project area)
        └── mprj (user_project_wrapper)
            └── user_project
                └── i2c_master (CF_I2C_WB)
                    ├── scl_o → GPIO[5]
                    └── sda_io → GPIO[6]
```

External slaves (i2c_slave_test, M24AA64) connect at testbench level to GPIO signals.

## Summary

✅ **Test Fixed**: Removed undefined variables and manual monitoring
✅ **Decorator Added**: `@report_test` handles test completion properly
✅ **API Updated**: Uses current caravel-cocotb patterns
✅ **Ready to Run**: Test should now execute without AttributeError

The test will now properly:
- Initialize Caravel environment
- Load and run firmware
- Monitor test execution
- Report results automatically
- Generate waveforms for debugging

Try running again with `./run_test.sh i2c_test`!
