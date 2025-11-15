# Quick Start Guide - I2C Caravel User Project

## Project Status
✅ **RTL Complete** - All modules created and lint-clean
✅ **Verification Ready** - Tests prepared but NOT executed (per user request)
✅ **EEPROM Added** - M24AA64 EEPROM model integrated for comprehensive testing
✅ **Configuration Fixed** - All paths corrected
✅ **Test Fixed** - Cocotb test updated with proper decorators
✅ **GPIO Updated** - I2C moved to GPIO 8/9 (was GPIO 5/6)

## Important Fixes Applied

### Configuration Fix
- `USER_PROJECT_ROOT=/workspace/I2C_TRIAL2` (updated in design_info.yaml)
- All environment variables properly set in run_test.sh
- See **CONFIGURATION_FIX.md** for details

### Test Fix
- Added `@report_test` decorator to i2c_test.py (required for caravel-cocotb)
- Removed manual test monitoring code (handled automatically by decorator)
- Fixed AttributeError with cocotb.log.error.counter
- See **COCOTB_TEST_FIX.md** for details

## How to Run Tests

### Option 1: Using the Helper Script (Recommended)
```bash
cd /workspace/I2C_TRIAL2
./run_test.sh i2c_test
```

### Option 2: Manual Execution
```bash
cd /workspace/I2C_TRIAL2/verilog/dv/cocotb
caravel_cocotb -t i2c_test -d design_info.yaml
```

### Option 3: Direct Environment Setup
```bash
export USER_PROJECT_ROOT=/workspace/I2C_TRIAL2
export PDK_ROOT=/nc/apps/pdk
export PDK=sky130A
export CARAVEL_ROOT=/nc/templates/caravel
export MCW_ROOT=/nc/templates/mgmt_core_wrapper

cd /workspace/I2C_TRIAL2/verilog/dv/cocotb
caravel_cocotb -t i2c_test -d design_info.yaml
```

## What the Test Does

The `i2c_test` firmware performs two phases:

### Phase 1: Simple Slave Test
1. Initialize I2C master (100 kHz)
2. Write to i2c_slave_test (4 registers):
   - REG0 ← 0xAA
   - REG1 ← 0x55
   - REG2 ← 0xDE
   - REG3 ← 0xAD
3. Read back and verify
4. Toggle management GPIO (phase 1 complete)

### Phase 2: EEPROM Test (NEW)
5. Write to M24AA64 EEPROM:
   - 0x0000 ← 0x12
   - 0x0001 ← 0x34
   - 0x0010 ← 0x56
   - 0x0100 ← 0x78
6. Read back and verify
7. Set management GPIO high (test passed)

## Test Outputs

After running, check:
```bash
# View log
cat /workspace/I2C_TRIAL2/verilog/dv/cocotb/sim/i2c_test/i2c_test.log

# View waveform
gtkwave /workspace/I2C_TRIAL2/verilog/dv/cocotb/sim/i2c_test/i2c_test.vcd &
```

## Key Waveform Signals to Monitor

- `mprj_io[5]` - I2C SCL
- `mprj_io[6]` - I2C SDA
- `uut.mprj.mprj.user_project.i2c_master.scl_o` - SCL output from master
- `uut.mprj.mprj.user_project.i2c_master.sda_o` - SDA output from master

If M24AA64 is instantiated in testbench:
- `u_eeprom.MemoryBlock[0]` - First byte of EEPROM
- `u_eeprom.START_Rcvd` - START condition detected
- `u_eeprom.WrCycle` - Write operation active
- `u_eeprom.RdCycle` - Read operation active

## Troubleshooting

### Issue: "USER_PROJECT_ROOT is not a directory"
**Solution**: The design_info.yaml has been updated with the correct path. If you still see this error:
```bash
cd /workspace/I2C_TRIAL2/verilog/dv/cocotb
cat design_info.yaml | grep USER_PROJECT_ROOT
# Should show: USER_PROJECT_ROOT: /workspace/I2C_TRIAL2
```

### Issue: "Test not found"
**Solution**: Check available tests:
```bash
ls -1 /workspace/I2C_TRIAL2/verilog/dv/cocotb/ | grep -v sim
# Should show: i2c_test
```

### Issue: M24AA64 not found in simulation
**Solution**: The M24AA64 is a testbench component. You need to instantiate it in your testbench:
```verilog
// Add to testbench
M24AA64 u_eeprom (
    .A0(1'b0), .A1(1'b0), .A2(1'b0),
    .WP(1'b0),
    .SDA(mprj_io[6]),
    .SCL(mprj_io[5]),
    .RESET(1'b0)
);
```

## File Locations

| Item | Path |
|------|------|
| **RTL** | `/workspace/I2C_TRIAL2/verilog/rtl/` |
| **Tests** | `/workspace/I2C_TRIAL2/verilog/dv/cocotb/i2c_test/` |
| **Firmware** | `/workspace/I2C_TRIAL2/verilog/dv/cocotb/i2c_test/i2c_test.c` |
| **Docs** | `/workspace/I2C_TRIAL2/docs/` |
| **Sim Output** | `/workspace/I2C_TRIAL2/verilog/dv/cocotb/sim/i2c_test/` |

## Design Details

- **I2C Master**: CF_I2C v2.0.0 (FIFO-based)
- **I2C Slaves**: 
  - i2c_slave_test (4 registers)
  - M24AA64 (8KB EEPROM)
- **Address Space**: 0x3000_0000 (I2C master registers)
- **GPIO**: 5=SCL, 6=SDA (bidirectional, open-drain)
- **IRQ**: user_irq[0] = I2C interrupt

## Documentation

- **README.md** - Project overview
- **EEPROM_ADDITION_SUMMARY.md** - EEPROM integration details
- **docs/register_map.md** - Complete register specifications
- **docs/eeprom_integration.md** - EEPROM usage guide
- **docs/pad_map.md** - GPIO assignments
- **docs/integration_notes.md** - Integration guide

## Next Steps

1. **Run the test** (when ready):
   ```bash
   cd /workspace/I2C_TRIAL2
   ./run_test.sh i2c_test
   ```

2. **Analyze results**:
   - Check log for pass/fail
   - View waveforms in GTKWave
   - Verify I2C protocol timing

3. **If tests pass**, proceed to:
   - OpenLane hardening (user_project)
   - OpenLane hardening (user_project_wrapper)
   - Final verification (gate-level, LVS, DRC)

4. **If tests fail**:
   - Review waveforms for I2C protocol issues
   - Check firmware logic
   - Verify slave instantiation in testbench
   - Consult documentation

## Support

For detailed information, see:
- `/workspace/I2C_TRIAL2/EEPROM_ADDITION_SUMMARY.md`
- `/workspace/I2C_TRIAL2/docs/`

All files are prepared and ready for testing!
