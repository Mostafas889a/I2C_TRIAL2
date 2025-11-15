# I2C Caravel User Project

## Initial User Prompt
"Create a user project of 1 i2C connected and don't run it. Try to make slave for i2c and use it for testing"

## Project Overview
This project integrates an I2C master controller into a Caravel user project with a custom I2C slave module for verification. The design demonstrates proper I2C communication protocol implementation suitable for ASIC integration.

## Objectives
1. Integrate EF_I2C IP (I2C master controller) from pre-installed IPs
2. Create a custom I2C slave module for testing purposes
3. Implement proper Wishbone B4 interface for Caravel integration
4. Provide comprehensive verification using caravel-cocotb
5. Prepare the design for silicon-ready hardening (not executed in this phase)

## Design Components
- **I2C Master**: CF_I2C v2.0.0 IP with Wishbone interface (FIFO-based)
- **I2C Slave**: Custom slave module with 4-register interface for loopback testing (address 0x50)
- **Wishbone Integration**: Direct connection to CF_I2C_WB wrapper
- **Interrupt**: Single IRQ line from I2C master to user_irq[0]

## Implementation Details
- **Address Space**: Base 0x3000_0000 (full 64KB window for I2C master)
- **GPIO Pins**: 
  - GPIO 5: I2C SCL (bidirectional, open-drain)
  - GPIO 6: I2C SDA (bidirectional, open-drain)
- **Clock**: 25 MHz Wishbone clock
- **I2C Clock**: Configurable via prescaler (default 100 kHz with prescale = 62)

## Project Status
🟢 **RTL Complete** - Verification phase (tests created, not executed per user request)

## Files Created
### RTL
- `verilog/rtl/user_project.v` - Main user project with CF_I2C_WB instantiation
- `verilog/rtl/user_project_wrapper.v` - Caravel wrapper (updated)
- `verilog/rtl/i2c_slave_test.v` - Custom I2C slave for testing
- `verilog/includes/includes.rtl.caravel_user_project` - File list

### Verification
- `verilog/dv/cocotb/i2c_test/i2c_test.c` - Firmware test
- `verilog/dv/cocotb/i2c_test/i2c_test.h` - I2C driver header
- `verilog/dv/cocotb/i2c_test/i2c_test.py` - Cocotb test
- `verilog/dv/cocotb/i2c_test/design_info.yaml` - Test configuration

### Documentation
- `docs/register_map.md` - CF_I2C register specifications
- `docs/pad_map.md` - GPIO/pad assignments
- `docs/integration_notes.md` - Integration guide

### IP Management
- `ip/link_IPs.json` - IP dependencies (CF_I2C, CF_IP_UTIL)
- `ip/CF_I2C/` - Symlink to CF_I2C v2.0.0
- `ip/CF_IP_UTIL/` - Symlink to CF_IP_UTIL v1.0.0

## Verification Status
✅ All RTL modules are lint-clean (verilator --lint-only)
⏸️ Caravel-cocotb tests prepared but NOT executed (per user request)

## Next Steps (When Ready to Run)
1. Run caravel-cocotb verification: `cd verilog/dv/cocotb && make i2c_test`
2. Review waveforms and test results
3. Proceed to OpenLane hardening if verification passes