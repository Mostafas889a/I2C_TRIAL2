# Configuration Fix - USER_PROJECT_ROOT Path

## Issue Encountered
```
NotADirectoryError: USER_PROJECT_ROOT is not a directory 
USER_PROJECT_ROOT:/workspace/caravel_user_project
```

## Root Cause
The `verilog/dv/cocotb/design_info.yaml` file was pointing to the default template path `/workspace/caravel_user_project` instead of the actual project path `/workspace/I2C_TRIAL2`.

## Solution Applied

### 1. Updated design_info.yaml
**File**: `/workspace/I2C_TRIAL2/verilog/dv/cocotb/design_info.yaml`

**Before**:
```yaml
USER_PROJECT_ROOT: /workspace/caravel_user_project
```

**After**:
```yaml
USER_PROJECT_ROOT: /workspace/I2C_TRIAL2
```

### 2. Updated run_test.sh Script
**File**: `/workspace/I2C_TRIAL2/run_test.sh`

**Changes**:
- Set correct USER_PROJECT_ROOT environment variable
- Added all required environment variables (PDK_ROOT, CARAVEL_ROOT, MCW_ROOT)
- Changed working directory to cocotb root (not test subdirectory)
- Updated paths to match caravel-cocotb expectations

**Key Variables**:
```bash
export USER_PROJECT_ROOT=/workspace/I2C_TRIAL2
export PDK_ROOT=/nc/apps/pdk
export PDK=sky130A
export CARAVEL_ROOT=/nc/templates/caravel
export MCW_ROOT=/nc/templates/mgmt_core_wrapper
```

### 3. Updated cocotb_tests.py
**File**: `/workspace/I2C_TRIAL2/verilog/dv/cocotb/cocotb_tests.py`

**Changes**:
- Removed example test imports
- Added i2c_test import

**Content**:
```python
from i2c_test.i2c_test import i2c_test
```

## How to Run Tests Now

### Option 1: Using Helper Script (Easiest)
```bash
cd /workspace/I2C_TRIAL2
./run_test.sh i2c_test
```
This script automatically sets all environment variables and runs from the correct directory.

### Option 2: Manual Execution (Direct)
```bash
cd /workspace/I2C_TRIAL2/verilog/dv/cocotb
caravel_cocotb -t i2c_test -d design_info.yaml
```
The design_info.yaml now has the correct path, so this should work directly.

### Option 3: With Explicit Environment (Most Control)
```bash
export USER_PROJECT_ROOT=/workspace/I2C_TRIAL2
export PDK_ROOT=/nc/apps/pdk
export PDK=sky130A
export CARAVEL_ROOT=/nc/templates/caravel
export MCW_ROOT=/nc/templates/mgmt_core_wrapper

cd /workspace/I2C_TRIAL2/verilog/dv/cocotb
caravel_cocotb -t i2c_test -d design_info.yaml
```

## Verification

To verify the configuration is correct:

### Check design_info.yaml
```bash
cat /workspace/I2C_TRIAL2/verilog/dv/cocotb/design_info.yaml | grep USER_PROJECT_ROOT
```
**Expected Output**:
```
USER_PROJECT_ROOT: /workspace/I2C_TRIAL2
```

### Check directory exists
```bash
ls -la /workspace/I2C_TRIAL2/verilog/
```
**Expected Output**: Should show `rtl/`, `dv/`, `includes/` directories

### Check test structure
```bash
ls -la /workspace/I2C_TRIAL2/verilog/dv/cocotb/
```
**Expected Output**: Should show `i2c_test/` directory and `design_info.yaml` file

## Files Modified

1. ✅ `/workspace/I2C_TRIAL2/verilog/dv/cocotb/design_info.yaml`
   - Fixed USER_PROJECT_ROOT path

2. ✅ `/workspace/I2C_TRIAL2/run_test.sh`
   - Added all environment variables
   - Fixed working directory
   - Improved error handling

3. ✅ `/workspace/I2C_TRIAL2/verilog/dv/cocotb/cocotb_tests.py`
   - Removed template imports
   - Added i2c_test import

## Additional Documentation

- **QUICK_START.md** - Quick reference for running tests
- **EEPROM_ADDITION_SUMMARY.md** - Details on M24AA64 integration
- **README.md** - Project overview (updated with correct paths)

## Understanding caravel-cocotb Directory Structure

The caravel-cocotb tool expects this structure:

```
USER_PROJECT_ROOT/
├── verilog/
│   ├── rtl/                          # RTL source files
│   │   ├── user_project_wrapper.v
│   │   ├── user_project.v
│   │   ├── i2c_slave_test.v
│   │   └── M24AA64.v
│   ├── includes/                     # Verilog include files
│   │   └── includes.rtl.caravel_user_project
│   └── dv/
│       └── cocotb/                   # Cocotb root (work here)
│           ├── design_info.yaml      # Main config (FIXED)
│           ├── cocotb_tests.py       # Test registry (UPDATED)
│           ├── i2c_test/             # Test directory
│           │   ├── i2c_test.py       # Test code
│           │   ├── i2c_test.c        # Firmware
│           │   ├── i2c_test.h        # Headers
│           │   └── design_info.yaml  # Test-specific config
│           └── sim/                  # Generated simulation outputs
│               └── i2c_test/
│                   ├── i2c_test.vcd  # Waveform
│                   └── i2c_test.log  # Log file
```

**Key Points**:
1. `caravel_cocotb` must be run from the `cocotb/` directory
2. The main `design_info.yaml` at cocotb root contains global settings
3. Each test can have its own `design_info.yaml` for test-specific overrides
4. USER_PROJECT_ROOT must point to the repository root

## Common Mistakes to Avoid

❌ **Don't**: Run from test subdirectory (`/workspace/I2C_TRIAL2/verilog/dv/cocotb/i2c_test/`)
✅ **Do**: Run from cocotb root (`/workspace/I2C_TRIAL2/verilog/dv/cocotb/`)

❌ **Don't**: Use template path in design_info.yaml
✅ **Do**: Use actual project path (`/workspace/I2C_TRIAL2`)

❌ **Don't**: Forget to set environment variables
✅ **Do**: Use `run_test.sh` which sets everything automatically

## Testing the Fix

Run this command to test everything is working:
```bash
cd /workspace/I2C_TRIAL2
./run_test.sh i2c_test
```

If you see the compilation starting and Icarus Verilog/Verilator building, the configuration is correct!

## Expected Behavior

When you run the test, you should see:
1. Environment variables printed
2. "Running test: i2c_test" message
3. Compilation of RTL and testbench
4. Firmware compilation
5. Simulation execution
6. Test results (pass/fail)
7. Output files in `sim/i2c_test/`

## Troubleshooting

### Still getting path errors?
Check that design_info.yaml was actually updated:
```bash
grep -n USER_PROJECT_ROOT /workspace/I2C_TRIAL2/verilog/dv/cocotb/design_info.yaml
```

### Permission errors on run_test.sh?
Make sure it's executable:
```bash
chmod +x /workspace/I2C_TRIAL2/run_test.sh
```

### Can't find test?
Check test registration:
```bash
cat /workspace/I2C_TRIAL2/verilog/dv/cocotb/cocotb_tests.py
```

Should contain:
```python
from i2c_test.i2c_test import i2c_test
```

## Summary

✅ **Configuration Fixed**: All paths corrected
✅ **Scripts Updated**: Helper script with all environment variables
✅ **Tests Ready**: Can now run with `./run_test.sh i2c_test`
✅ **Documentation Complete**: QUICK_START.md for reference

The project is now properly configured and ready to run tests!
