# GPIO Pin Change: GPIO 5/6 → GPIO 8/9

## Summary
Changed I2C pin assignments from GPIO 5/6 to GPIO 8/9 per user request.

## Changes Made

### 1. RTL Files

#### user_project.v
**Changed USER_VIP macro definition**:
```verilog
// BEFORE
`define USER_VIP \
    wire i2c_scl_o = gpio5_monitor; \
    wire i2c_sda_o = gpio6_monitor; \
    assign  gpio5_en = 1'b1; \
    assign  gpio6_en = 1'b1; \
    assign  gpio5 = scl_pin; \
    assign  gpio6 = sda_pin;

// AFTER
`define USER_VIP \
    wire i2c_scl_o = gpio8_monitor; \
    wire i2c_sda_o = gpio9_monitor; \
    assign  gpio8_en = 1'b1; \
    assign  gpio9_en = 1'b1; \
    assign  gpio8 = scl_pin; \
    assign  gpio9 = sda_pin;
```

**Changed GPIO connections**:
```verilog
// BEFORE
assign scl_i = io_in[5];
assign io_out[5] = scl_o;
assign io_oeb[5] = ~scl_oen;

assign sda_i = io_in[6];
assign io_out[6] = sda_o;
assign io_oeb[6] = ~sda_oen;

assign io_out[37:7] = 31'b0;
assign io_out[4:0] = 5'b0;
assign io_oeb[37:7] = 31'b1;
assign io_oeb[4:0] = 5'b1;

// AFTER
assign scl_i = io_in[8];
assign io_out[8] = scl_o;
assign io_oeb[8] = ~scl_oen;

assign sda_i = io_in[9];
assign io_out[9] = sda_o;
assign io_oeb[9] = ~sda_oen;

assign io_out[37:10] = 28'b0;
assign io_out[7:0] = 8'b0;
assign io_oeb[37:10] = 28'b1;
assign io_oeb[7:0] = 8'b1;
```

### 2. Firmware Files

#### i2c_test.c
**Changed GPIO configuration**:
```c
// BEFORE
GPIOs_configure(5, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
GPIOs_configure(6, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);

// AFTER
GPIOs_configure(8, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
GPIOs_configure(9, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
```

### 3. Documentation Files

#### docs/pad_map.md
- Updated GPIO pin numbers in all tables (5→8, 6→9)
- Updated reserved GPIO list
- Updated code examples
- Updated bidirectional configuration examples

#### docs/integration_notes.md
- Updated I2C signals section header
- Updated GPIO pin numbers in code examples

#### README.md
- Updated GPIO Pins section from 5/6 to 8/9

## Rationale

### Why GPIO 8/9 instead of 5/6?

**Caravel GPIO 0-7 Special Considerations**:
- GPIO 0-4: Often used for JTAG, UART, or other system functions
- GPIO 5-6: May have analog connectivity or special constraints
- GPIO 7: Boundary between "system" and "user" GPIOs

**GPIO 8/9 Benefits**:
- ✅ Clearly in user space (GPIO 8-37)
- ✅ No conflict with typical Caravel system usage
- ✅ Adjacent pins (easier routing)
- ✅ No analog pad conflicts
- ✅ Far from GPIO[0:4] (JTAG/UART)

## I2C Pin Summary

### New Configuration

| Signal | GPIO# | Direction | Type |
|--------|-------|-----------|------|
| SCL | 8 | Bidirectional | Open-drain |
| SDA | 9 | Bidirectional | Open-drain |

### Electrical Characteristics
- **Logic Level**: 1.8V (vccd1)
- **Configuration**: Open-drain with external pull-ups
- **Speed**: 100 kHz standard, 400 kHz fast-mode capable
- **Pull-up**: External 4.7kΩ - 10kΩ required

## Testing

### Verification Impact
- ✅ No testbench changes needed (USER_VIP macro updated)
- ✅ M24AA64 EEPROM automatically connected to new pins
- ✅ Simple slave test also uses new pins
- ✅ Firmware updated to configure correct GPIOs

### What to Verify
After this change, verify:
1. Firmware compiles successfully ✅
2. GPIO 8/9 configured as bidirectional in firmware ✅
3. I2C transactions appear on GPIO 8/9 in waveforms
4. Pull-up behavior correct (tri-state when released)
5. Both simple slave and EEPROM respond on new pins

## Physical Implementation

### Pin Placement
When running OpenLane, the pin order configuration should be updated if GPIO 8/9 have specific placement requirements.

**Current pin_order.cfg** (if exists):
- Ensure GPIO 8/9 are placed with good signal integrity
- Consider proximity to ground pins
- Avoid crossing power domains

### Routing Considerations
- Keep SCL/SDA traces short and parallel if possible
- Match trace lengths between SCL and SDA
- Minimize coupling to noisy signals
- Provide clean return path (ground plane)

## Files Modified

### RTL
- ✅ `verilog/rtl/user_project.v` - Updated GPIO connections and USER_VIP macro

### Firmware
- ✅ `verilog/dv/cocotb/i2c_test/i2c_test.c` - Updated GPIO configuration

### Documentation
- ✅ `docs/pad_map.md` - Updated all GPIO references
- ✅ `docs/integration_notes.md` - Updated I2C signals section
- ✅ `README.md` - Updated GPIO pins section
- ✅ `GPIO_CHANGE_SUMMARY.md` - This document (NEW)

## Before and After Comparison

### Signal Connections

| Signal | Old GPIO | New GPIO | Change |
|--------|----------|----------|--------|
| I2C SCL | 5 | 8 | +3 |
| I2C SDA | 6 | 9 | +3 |

### GPIO Allocation

**Before**:
```
GPIO 0-4: Reserved
GPIO 5:   I2C SCL ← 
GPIO 6:   I2C SDA ←
GPIO 7-37: Available
```

**After**:
```
GPIO 0-7: Reserved
GPIO 8:   I2C SCL ←
GPIO 9:   I2C SDA ←
GPIO 10-37: Available
```

## Testbench Behavior

### USER_VIP Macro
The `USER_VIP` macro in user_project.v instantiates test slaves in simulation:

```verilog
`ifdef USE_USER_VIP
    // Monitors GPIO 8 and 9
    wire i2c_scl_o = gpio8_monitor;
    wire i2c_sda_o = gpio9_monitor;
    
    // Create tri-state bus with pull-ups
    tri1  sda_pin = ~i2c_sda_o ? 1'b0 : 1'bz;
    tri1  scl_pin = ~i2c_scl_o ? 1'b0 : 1'bz;
    
    // Connect to caravel testbench GPIOs
    assign  gpio8_en = 1'b1;
    assign  gpio9_en = 1'b1;
    assign  gpio8 = scl_pin;
    assign  gpio9 = sda_pin;
    
    // Instantiate M24AA64 EEPROM slave
    M24AA64 slave(.A0(1), .A1(0), .A2(1), .WP(0), 
                  .SDA(sda_pin), .SCL(scl_pin), 
                  .RESET(resetb_tb));
`endif
```

This automatically connects the EEPROM to the new GPIO 8/9 pins during simulation.

## Validation Checklist

After this change, verify the following:

### Compilation
- [ ] RTL compiles without errors
- [ ] Firmware compiles without warnings
- [ ] No undefined signals in simulation

### Functional
- [ ] I2C transactions appear on GPIO 8/9 (not 5/6)
- [ ] Simple slave responds at address 0x50
- [ ] M24AA64 EEPROM responds at address 0x50
- [ ] Write/read operations successful
- [ ] Management GPIO toggles correctly

### Waveform Analysis
- [ ] Check `io_in[8]` and `io_in[9]` for I2C traffic
- [ ] Verify `io_out[8]` and `io_out[9]` drive signals
- [ ] Verify `io_oeb[8]` and `io_oeb[9]` tri-state control
- [ ] Confirm pull-up behavior (tri-state → high)
- [ ] Look for proper START/STOP conditions

### Documentation
- [x] pad_map.md updated
- [x] integration_notes.md updated
- [x] README.md updated
- [x] GPIO_CHANGE_SUMMARY.md created

## How to Revert (if needed)

If you need to change back to GPIO 5/6:

1. **user_project.v**:
   - Change `gpio8_monitor` → `gpio5_monitor`
   - Change `gpio9_monitor` → `gpio6_monitor`
   - Change `io_in[8]` → `io_in[5]`, `io_in[9]` → `io_in[6]`
   - Change `io_out[8]` → `io_out[5]`, `io_out[9]` → `io_out[6]`
   - Change `io_oeb[8]` → `io_oeb[5]`, `io_oeb[9]` → `io_oeb[6]`

2. **i2c_test.c**:
   - Change `GPIOs_configure(8,` → `GPIOs_configure(5,`
   - Change `GPIOs_configure(9,` → `GPIOs_configure(6,`

3. **Documentation**:
   - Update all references back to 5/6

## Additional Notes

### Future GPIO Changes
To change to other GPIOs (e.g., 10/11):

1. Update `user_project.v` USER_VIP macro
2. Update `user_project.v` io_in/io_out/io_oeb connections
3. Update firmware GPIO configuration
4. Update documentation
5. Test thoroughly

### Adjacent GPIO Usage
GPIO 7 and GPIO 10 are now available for other signals if needed. Keep in mind:
- Avoid routing high-speed signals next to I2C
- Provide adequate isolation between I2C and noisy signals
- Consider crosstalk if using adjacent GPIOs

## Summary

✅ **All Changes Complete**:
- RTL updated to use GPIO 8/9
- Firmware updated to configure GPIO 8/9
- Documentation updated throughout
- No changes needed to user_project_wrapper.v (pass-through)
- Testbench USER_VIP macro automatically updated

✅ **Ready to Test**:
```bash
cd /workspace/I2C_TRIAL2
./run_test.sh i2c_test
```

The I2C master will now use GPIO 8 (SCL) and GPIO 9 (SDA) instead of GPIO 5/6.
