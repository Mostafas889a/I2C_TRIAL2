# Latest Changes - GPIO 8/9 Update

## Change Request
User requested: "use different gpio than 5 and 6 to connect i2c"

## Action Taken
Changed I2C pin assignments from **GPIO 5/6** to **GPIO 8/9**

## Files Modified

### 1. RTL (verilog/rtl/user_project.v)
✅ Updated USER_VIP macro:
- `gpio5_monitor` → `gpio8_monitor`
- `gpio6_monitor` → `gpio9_monitor`
- `gpio5` → `gpio8`
- `gpio6` → `gpio9`

✅ Updated I2C pin connections:
- `io_in[5]` → `io_in[8]` (SCL input)
- `io_out[5]` → `io_out[8]` (SCL output)
- `io_oeb[5]` → `io_oeb[8]` (SCL output enable)
- `io_in[6]` → `io_in[9]` (SDA input)
- `io_out[6]` → `io_out[9]` (SDA output)
- `io_oeb[6]` → `io_oeb[9]` (SDA output enable)

✅ Updated unused GPIO assignments:
- Changed from `[37:7]/[4:0]` to `[37:10]/[7:0]`

### 2. Firmware (verilog/dv/cocotb/i2c_test/i2c_test.c)
✅ Updated GPIO configuration:
```c
// BEFORE
GPIOs_configure(5, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
GPIOs_configure(6, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);

// AFTER
GPIOs_configure(8, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
GPIOs_configure(9, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
```

### 3. Documentation
✅ **docs/pad_map.md** - Updated all GPIO references (tables, code examples, diagrams)
✅ **docs/integration_notes.md** - Updated I2C signals section
✅ **README.md** - Updated GPIO Pins section
✅ **QUICK_START.md** - Added GPIO change notice
✅ **GPIO_CHANGE_SUMMARY.md** - Created comprehensive change documentation

## New Pin Assignment

| Signal | GPIO# | Direction | Configuration |
|--------|-------|-----------|---------------|
| I2C SCL | 8 | Bidirectional | Open-drain with pull-up |
| I2C SDA | 9 | Bidirectional | Open-drain with pull-up |

## Why GPIO 8/9?

✅ **Benefits**:
- Clearly in user GPIO space (GPIO 8-37)
- No conflict with Caravel system GPIOs (0-4)
- No conflict with typical UART/JTAG usage (GPIO 5-6)
- Adjacent pins for easier routing
- No analog pad conflicts

## Impact Assessment

### ✅ No Impact (Automatically Handled)
- user_project_wrapper.v (pass-through, no changes needed)
- Testbench USER_VIP macro (updated automatically)
- M24AA64 EEPROM connection (uses macro, updated automatically)
- Simple slave connection (uses macro, updated automatically)

### ✅ Updated Successfully
- RTL GPIO connections
- Firmware GPIO configuration
- All documentation

### 🔍 Need to Verify in Testing
- I2C transactions appear on GPIO 8/9 in waveforms
- Both slaves respond correctly on new pins
- Management GPIO still works for test pass/fail

## How to Test

Run the test to verify GPIO 8/9 work correctly:
```bash
cd /workspace/I2C_TRIAL2
./run_test.sh i2c_test
```

### What to Check in Waveforms
1. Open `sim/i2c_test/i2c_test.vcd` in GTKWave
2. Add signals:
   - `uut.mprj.io_in[8]` (SCL input)
   - `uut.mprj.io_out[8]` (SCL output)
   - `uut.mprj.io_oeb[8]` (SCL tri-state control)
   - `uut.mprj.io_in[9]` (SDA input)
   - `uut.mprj.io_out[9]` (SDA output)
   - `uut.mprj.io_oeb[9]` (SDA tri-state control)
3. Verify I2C START/STOP/ACK patterns appear
4. Confirm tri-state behavior (oeb toggles correctly)

## Expected Behavior

### Firmware Sequence
1. Configure GPIO 8 as bidirectional ✅
2. Configure GPIO 9 as bidirectional ✅
3. Initialize I2C master (prescale=62, 100kHz) ✅
4. **Phase 1**: Test simple slave at 0x50
   - Write 4 bytes, read back
5. **Phase 2**: Test M24AA64 EEPROM at 0x50
   - Write 4 addresses with 2-byte addressing
   - Read back and verify
6. Set management GPIO=1 if all passed

### I2C Bus Behavior
- **GPIO 8 (SCL)**: Clock pulses at ~100 kHz
- **GPIO 9 (SDA)**: Data transitions synchronized with SCL
- **Pull-ups**: Both lines idle HIGH (tri-state)
- **Open-drain**: Drive LOW or release (HIGH)

## Verification Checklist

- [ ] Firmware compiles without errors
- [ ] RTL synthesizes cleanly
- [ ] Test executes without errors
- [ ] I2C traffic visible on GPIO 8/9 in waveforms
- [ ] Simple slave responds correctly
- [ ] EEPROM responds correctly
- [ ] Management GPIO toggles for pass/fail
- [ ] No activity on old GPIO 5/6

## Documentation Structure

```
/workspace/I2C_TRIAL2/
├── README.md                      # Updated GPIO 8/9
├── QUICK_START.md                 # Added GPIO change notice
├── GPIO_CHANGE_SUMMARY.md         # Detailed change doc (NEW)
├── LATEST_CHANGES.md              # This file (NEW)
├── verilog/
│   ├── rtl/
│   │   └── user_project.v         # Updated GPIO connections
│   └── dv/
│       └── cocotb/
│           └── i2c_test/
│               └── i2c_test.c     # Updated GPIO config
└── docs/
    ├── pad_map.md                 # Updated GPIO 8/9
    └── integration_notes.md       # Updated GPIO 8/9
```

## Comparison: Before vs After

### Pin Usage
```
BEFORE:
GPIO 0-4: Caravel system
GPIO 5:   I2C SCL ← (old)
GPIO 6:   I2C SDA ← (old)
GPIO 7-37: Available

AFTER:
GPIO 0-7: Caravel system (reserved)
GPIO 8:   I2C SCL ← (new)
GPIO 9:   I2C SDA ← (new)
GPIO 10-37: Available
```

### Code Changes Summary
- **RTL**: 3 sections changed (macro, connections, unused assignments)
- **Firmware**: 2 lines changed (GPIO configure calls)
- **Documentation**: 5 files updated

## Summary

✅ **Change Complete**: I2C successfully moved to GPIO 8/9
✅ **All Files Updated**: RTL, firmware, documentation all consistent
✅ **Automatic Propagation**: Testbench slaves automatically connected to new pins
✅ **Ready to Test**: Run `./run_test.sh i2c_test` to verify

The I2C master and both test slaves (simple slave + M24AA64 EEPROM) now operate on GPIO 8 (SCL) and GPIO 9 (SDA) instead of GPIO 5/6.
