# M24AA64 EEPROM Integration Guide

## Overview
The M24AA64 is a Microchip 64K-bit (8KB) I2C EEPROM that has been added to the I2C test infrastructure. This provides a realistic I2C slave device for comprehensive testing of the CF_I2C master controller.

## Module Information
- **Model**: M24AA64 (24AA64.v from Young Engineering)
- **Capacity**: 8192 bytes (8KB)
- **Interface**: Standard I2C (100 kHz / 400 kHz)
- **Page Size**: 32 bytes
- **I2C Address**: 0x50 (configurable via A2, A1, A0 pins)
- **Address Width**: 13 bits (0x0000 - 0x1FFF)

## Integration Architecture

```
┌──────────────────────────────────────────────────────┐
│  Caravel SoC                                          │
│                                                       │
│  ┌────────────────────────────────────────────────┐  │
│  │  user_project                                  │  │
│  │                                                │  │
│  │  ┌──────────────────┐                         │  │
│  │  │  CF_I2C_WB       │  SCL ────────────────┐  │  │
│  │  │  (I2C Master)    │  SDA ────────────┐   │  │  │
│  │  └──────────────────┘                  │   │  │  │
│  └─────────────────────────────────────────┼───┼──┘  │
└────────────────────────────────────────────┼───┼─────┘
                                             │   │
                      External I2C Bus ──────┴───┴────
                      (with pull-up resistors)
                                             │   │
                 ┌───────────────────────────┴───┴────────┐
                 │                                         │
        ┌────────┴─────────┐           ┌─────────────────┴┐
        │ i2c_slave_test    │           │  M24AA64          │
        │ (Simple 4-reg)    │           │  (EEPROM Model)   │
        │ Address: 0x50     │           │  Address: 0x50    │
        └───────────────────┘           └───────────────────┘
        (Original test slave)            (Added test slave)
```

**Note**: Both slaves use address 0x50. In simulation, both will respond. For proper testing:
- Use different addresses (e.g., configure i2c_slave_test to 0x48 or disable it)
- OR instantiate them in separate test scenarios

## Files Modified

### RTL Files
1. **verilog/rtl/M24AA64.v** (NEW)
   - Complete EEPROM behavioral model
   - Includes timing checks and write cycle delays
   - Debug signals for waveform inspection

2. **verilog/includes/includes.rtl.caravel_user_project** (UPDATED)
   - Added M24AA64.v to compilation list

### Firmware Files
3. **verilog/dv/cocotb/i2c_test/i2c_test.h** (UPDATED)
   - Added `i2c_eeprom_write()` function for 2-byte address writes
   - Added `i2c_eeprom_read()` function for 2-byte address reads
   - Helper functions handle EEPROM protocol automatically

4. **verilog/dv/cocotb/i2c_test/i2c_test.c** (UPDATED)
   - Extended test to include EEPROM operations
   - Tests both simple slave and EEPROM in sequence
   - Verifies write/read at multiple address locations

### Documentation Files
5. **docs/register_map.md** (UPDATED)
   - Complete M24AA64 register and protocol documentation
   - Memory organization details
   - Timing specifications
   - C API examples

6. **docs/eeprom_integration.md** (NEW - THIS FILE)
   - Integration guide and usage instructions

7. **README.md** (UPDATED)
   - Updated design components section

## Test Scenario

The updated firmware test (`i2c_test.c`) performs:

### Phase 1: Simple Slave Test (Original)
1. Initialize I2C master (prescale = 62 for 100 kHz)
2. Write test patterns to i2c_slave_test registers:
   - REG0 ← 0xAA
   - REG1 ← 0x55
   - REG2 ← 0xDE
   - REG3 ← 0xAD
3. Read back and verify
4. Signal phase 1 complete via management GPIO

### Phase 2: EEPROM Test (NEW)
5. Write to EEPROM at various addresses:
   - 0x0000 ← 0x12
   - 0x0001 ← 0x34
   - 0x0010 ← 0x56
   - 0x0100 ← 0x78
6. Read back from EEPROM and verify
7. Signal phase 2 complete via management GPIO

## Usage Instructions

### Simulation Instantiation
The M24AA64 should be instantiated in the testbench, NOT in the user_project:

```verilog
// In testbench (e.g., caravel_top_tb.v or cocotb environment)
wire i2c_scl;
wire i2c_sda;

// Pull-up resistors (required for open-drain I2C)
pullup(i2c_scl);
pullup(i2c_sda);

// Instantiate EEPROM
M24AA64 eeprom_inst (
    .A0(1'b0),
    .A1(1'b0),
    .A2(1'b0),
    .WP(1'b0),
    .SDA(i2c_sda),
    .SCL(i2c_scl),
    .RESET(1'b0)
);

// Connect to Caravel GPIO
assign i2c_scl = mprj_io[5];
assign i2c_sda = mprj_io[6];
```

### Address Configuration
The EEPROM I2C address is configured via the A2, A1, A0 pins:

| A2 | A1 | A0 | Address |
|----|----|-----|---------|
| 0  | 0  | 0   | 0x50    |
| 0  | 0  | 1   | 0x51    |
| 0  | 1  | 0   | 0x52    |
| ... | ... | ... | ...     |
| 1  | 1  | 1   | 0x57    |

### Write Protect (WP) Pin
- **WP = 0**: Write enabled (normal operation)
- **WP = 1**: Write protected (only read operations allowed)

## Firmware API

### EEPROM Write
```c
void i2c_eeprom_write(uint8_t slave_addr, uint16_t addr, uint8_t data);
```
- Writes a single byte to EEPROM
- Handles 2-byte addressing automatically
- Waits for I2C transaction to complete
- **Note**: In real hardware, add 5ms delay after write for write cycle

### EEPROM Read
```c
uint8_t i2c_eeprom_read(uint8_t slave_addr, uint16_t addr);
```
- Reads a single byte from EEPROM
- Handles 2-byte addressing and repeated START
- Waits for data in read FIFO
- Returns data byte

### Example Usage
```c
// Write to EEPROM
i2c_eeprom_write(0x50, 0x0100, 0xAB);

// Optional: Wait for write cycle in real hardware
// delay_ms(5);

// Read from EEPROM
uint8_t data = i2c_eeprom_read(0x50, 0x0100);

if (data == 0xAB) {
    // Success!
}
```

## Timing Considerations

### Write Cycle Time (tWC)
- **Specification**: 5 ms maximum
- **Simulation**: Modeled with `#(tWC)` delay in Verilog
- **Real Hardware**: Must wait or poll for write completion

### Clock Frequency
- **Standard Mode**: 100 kHz (prescale = 62 @ 25 MHz system clock)
- **Fast Mode**: 400 kHz (prescale = 15 @ 25 MHz system clock)

### SCL/SDA Timing
The model includes timing checks for:
- SCL high/low pulse widths
- Setup and hold times
- START/STOP condition timing

## Debug Features

The M24AA64 model includes debug wires for waveform inspection:

### Memory Content Debug
```verilog
wire [7:0] MemoryByte_000 = MemoryBlock[0];
wire [7:0] MemoryByte_001 = MemoryBlock[1];
// ... (16 bytes visible in waveforms)
```

### Write Buffer Debug
```verilog
wire [7:0] WriteData_00 = WrDataByte[0];
wire [7:0] WriteData_01 = WrDataByte[1];
// ... (32 bytes page buffer visible)
```

### State Signals
- `START_Rcvd`: START condition detected
- `STOP_Rcvd`: STOP condition detected
- `CTRL_Rcvd`: Control byte (device address) received
- `WrCycle`: Write cycle in progress
- `RdCycle`: Read cycle in progress
- `WriteActive`: Internal write cycle timer active

## Testing Recommendations

### Basic Functional Test
1. Write single byte to address 0x0000
2. Read back and verify
3. Write to different addresses (0x0001, 0x0100, 0x1000)
4. Verify no cross-contamination

### Page Boundary Test
1. Write 32 bytes starting at page-aligned address (e.g., 0x0000)
2. Write crossing page boundary (e.g., 20 bytes at 0x001F)
3. Verify wrap-around behavior

### Address Range Test
1. Write to first address (0x0000)
2. Write to last address (0x1FFF)
3. Write to mid-range (0x1000)
4. Verify all accessible

### Write Protect Test
1. Set WP = 1
2. Attempt write operation
3. Verify write is blocked
4. Set WP = 0
5. Verify write succeeds

## Known Limitations

### Simulation Only
- This is a behavioral model for simulation
- Not synthesizable (contains delays, timing checks)
- For testbench instantiation only

### Timing Accuracy
- Timing checks are approximate
- Real silicon timing may vary
- Use for functional verification only

### Address Conflict
- Both i2c_slave_test and M24AA64 default to address 0x50
- For proper testing, either:
  - Change i2c_slave_test address parameter
  - Use different address pins on M24AA64
  - Run separate test scenarios

## Benefits of EEPROM Model

1. **Realistic Testing**: Tests actual EEPROM protocol with 2-byte addressing
2. **Memory Depth**: 8KB provides substantial test space
3. **Page Writes**: Can test page boundary behavior
4. **Industry Standard**: M24AA64 is widely used, well-documented
5. **Timing Model**: Includes write cycle delays and timing checks
6. **Debug Visibility**: Built-in debug signals for waveform analysis

## Next Steps

1. **Run Simulation**: Execute caravel-cocotb test with EEPROM instantiated
2. **Analyze Waveforms**: Check I2C protocol timing and data integrity
3. **Extend Tests**: Add page write tests, address boundary tests
4. **Performance**: Test at different I2C clock speeds (100 kHz, 400 kHz)
5. **Error Cases**: Test NACK handling, address overflow, etc.

## References

- **Datasheet**: Microchip 24AA64/24LC64 64K I2C Serial EEPROM
- **Model Source**: Young Engineering (www.young-engineering.com)
- **I2C Specification**: NXP I2C-bus specification and user manual (UM10204)
- **CF_I2C Documentation**: /workspace/I2C_TRIAL2/ip/CF_I2C/README.md
