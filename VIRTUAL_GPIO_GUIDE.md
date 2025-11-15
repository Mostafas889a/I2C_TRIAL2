# VirtualGPIOModel Usage Guide

## Overview

`VirtualGPIOModel` is a caravel-cocotb utility that provides a **virtual GPIO interface** for communication between firmware and testbench. It implements a memory-mapped GPIO register that allows:

- **Firmware → Testbench**: Write data via Wishbone to control testbench behavior
- **Testbench → Firmware**: Read data via Wishbone to provide inputs to firmware

## Key Concepts

### Memory-Mapped GPIO Register
- **Address**: `0x30FFFFFC` (fixed)
- **Size**: 32 bits
- **Layout**:
  ```
  [31:16] = INPUT  (testbench → firmware, read-only for firmware)
  [15:0]  = OUTPUT (firmware → testbench, write/read for firmware)
  ```

### Purpose
- **Testbench Monitoring**: Python test can monitor what firmware is doing
- **Phase Indication**: Firmware can signal test phases via GPIO patterns
- **Test Result**: Firmware can signal pass/fail via GPIO state
- **Data Exchange**: Bidirectional data between firmware and testbench

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Firmware (C)                                     │
│                                                   │
│  Write to 0x30FFFFFC:                            │
│    reg_write(0x30FFFFFC, 0x0001);  // Set bit 0  │
│    ↓                                              │
└────┼──────────────────────────────────────────────┘
     │ Wishbone Bus
     ↓
┌────┼──────────────────────────────────────────────┐
│    │  VirtualGPIOModel (Python)                   │
│    │                                               │
│    └─► gpio_output[15:0] = captured value         │
│        ↓                                           │
│        Python test can read: virtual_gpio.get_output() │
│                                                    │
│    Testbench can write:                           │
│        virtual_gpio.set_input(0x1234)             │
│        ↓                                           │
│        gpio_input[15:0] = 0x1234                  │
│        ↓                                           │
│    Firmware reads from 0x30FFFFFC:                │
│        value = reg_read(0x30FFFFFC);              │
│        // value[31:16] = 0x1234                   │
│        // value[15:0]  = last written value       │
└────────────────────────────────────────────────────┘
```

## Python API

### Initialization
```python
from caravel_cocotb.caravel_interfaces import VirtualGPIOModel

virtual_gpio = VirtualGPIOModel(caravelEnv)
virtual_gpio.start()  # Start monitoring Wishbone transactions
```

### Reading Firmware Output
```python
# Get current output value (bits [15:0] written by firmware)
output = virtual_gpio.get_output()
print(f"Firmware wrote: 0x{output:04x}")
```

### Waiting for Specific Output
```python
# Wait until firmware writes a specific value
await virtual_gpio.wait_output(0x00FF)
cocotb.log.info("Firmware wrote 0x00FF - Phase 1 complete!")
```

### Waiting for Any Change
```python
# Wait until output changes from current value
await virtual_gpio.wait_for_change()
cocotb.log.info("Firmware updated GPIO output")
```

### Writing Input to Firmware
```python
# Set input that firmware can read (bits [31:16])
virtual_gpio.set_input(0x1234)
# Firmware can now read this value from bits [31:16]
```

## Firmware API (C)

### Memory-Mapped Register Access
```c
#define VIRTUAL_GPIO_REG ((volatile uint32_t*)0x30FFFFFC)

// Write to output (testbench can read bits [15:0])
*VIRTUAL_GPIO_REG = 0x0001;

// Read from register
// bits [15:0]  = last value written
// bits [31:16] = value set by testbench via set_input()
uint32_t value = *VIRTUAL_GPIO_REG;
uint16_t output = value & 0xFFFF;         // What firmware wrote
uint16_t input = (value >> 16) & 0xFFFF;  // What testbench provided
```

### Helper Functions
```c
static inline void virtual_gpio_write(uint16_t value) {
    *((volatile uint32_t*)0x30FFFFFC) = value;
}

static inline uint16_t virtual_gpio_read_output(void) {
    return (*((volatile uint32_t*)0x30FFFFFC)) & 0xFFFF;
}

static inline uint16_t virtual_gpio_read_input(void) {
    return ((*((volatile uint32_t*)0x30FFFFFC)) >> 16) & 0xFFFF;
}
```

## Common Usage Patterns

### Pattern 1: Phase Indication
**Firmware**:
```c
virtual_gpio_write(0x0001);  // Phase 1 start
// ... do phase 1 work ...
virtual_gpio_write(0x0002);  // Phase 2 start
// ... do phase 2 work ...
virtual_gpio_write(0x0003);  // All phases complete
```

**Python Test**:
```python
await virtual_gpio.wait_output(0x0001)
cocotb.log.info("Phase 1 started")

await virtual_gpio.wait_output(0x0002)
cocotb.log.info("Phase 1 complete, Phase 2 started")

await virtual_gpio.wait_output(0x0003)
cocotb.log.info("All phases complete!")
```

### Pattern 2: Bit-Based Flags
**Firmware**:
```c
#define PHASE1_DONE (1 << 0)
#define PHASE2_DONE (1 << 1)
#define ALL_PASS    (1 << 15)

uint16_t status = 0;

// Phase 1 complete
status |= PHASE1_DONE;
virtual_gpio_write(status);

// Phase 2 complete
status |= PHASE2_DONE;
virtual_gpio_write(status);

// All tests passed
status |= ALL_PASS;
virtual_gpio_write(status);
```

**Python Test**:
```python
# Wait for Phase 1
while not (virtual_gpio.get_output() & 0x0001):
    await RisingEdge(caravelEnv.clk)
cocotb.log.info("Phase 1 done")

# Wait for Phase 2
while not (virtual_gpio.get_output() & 0x0002):
    await RisingEdge(caravelEnv.clk)
cocotb.log.info("Phase 2 done")

# Check final pass/fail
await Timer(1000, units='ns')
if virtual_gpio.get_output() & 0x8000:
    cocotb.log.info("TEST PASSED")
else:
    cocotb.log.error("TEST FAILED")
```

### Pattern 3: Data Exchange
**Testbench provides test data**:
```python
# Testbench sets test vector
virtual_gpio.set_input(0x1234)

# Wait for firmware to process
await virtual_gpio.wait_output(0xFFFF)

# Check result
result = virtual_gpio.get_output()
assert result == 0x1234, f"Expected 0x1234, got 0x{result:04x}"
```

**Firmware reads and echoes**:
```c
// Read test data from testbench
uint32_t reg = *VIRTUAL_GPIO_REG;
uint16_t test_data = (reg >> 16) & 0xFFFF;

// Process data (e.g., echo it back)
virtual_gpio_write(test_data);
```

## I2C Test Integration

### Our i2c_test.py Implementation
```python
from caravel_cocotb.caravel_interfaces import VirtualGPIOModel

@cocotb.test()
@report_test
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    # Start VirtualGPIO monitoring
    virtual_gpio = VirtualGPIOModel(caravelEnv)
    virtual_gpio.start()
    
    cocotb.log.info("[TEST] VirtualGPIOModel started")
    cocotb.log.info("[TEST] Monitoring GPIO at 0x30FFFFFC")
    
    # @report_test handles waiting and checking automatically
    # But we can still monitor progress if desired
```

### Our i2c_test.c Firmware
The firmware doesn't currently use VirtualGPIO (it uses management GPIO instead), but we **could** add it for better testbench integration:

**Current** (using management GPIO):
```c
ManagmentGpio_write(0);  // Clear
ManagmentGpio_write(1);  // Set (indicates completion)
```

**Enhanced** (using VirtualGPIO for detailed status):
```c
#define VGPIO ((volatile uint32_t*)0x30FFFFFC)

// Indicate test phases
*VGPIO = 0x0001;  // I2C init complete
// ... I2C slave test ...
*VGPIO = 0x0002;  // Simple slave test complete
// ... EEPROM test ...
*VGPIO = 0x0003;  // EEPROM test complete

// Final result
if (all_tests_passed) {
    *VGPIO = 0x00FF;  // All pass
} else {
    *VGPIO = 0x0000;  // Some failed
}
```

## Advantages of VirtualGPIOModel

### 1. Detailed Progress Monitoring
- Track each test phase individually
- Measure timing between phases
- Identify which phase failed

### 2. Bidirectional Communication
- Testbench can provide test vectors to firmware
- Firmware can return results to testbench
- Dynamic test scenarios possible

### 3. Non-Intrusive
- Uses memory-mapped I/O (standard Wishbone)
- No special hardware required
- Works with existing Caravel infrastructure

### 4. Debug Visibility
- All transactions logged automatically
- Easy to add cocotb.log messages
- Can correlate with waveforms

## Comparison: VirtualGPIO vs Management GPIO

| Feature | VirtualGPIO | Management GPIO |
|---------|-------------|-----------------|
| **Width** | 16 bits output, 16 bits input | 1 bit |
| **Direction** | Bidirectional | Output only (from firmware) |
| **Monitoring** | Python API with wait functions | Direct signal monitoring |
| **Use Case** | Detailed status, data exchange | Simple pass/fail indication |
| **Address** | 0x30FFFFFC (Wishbone) | Direct pin access |
| **Logging** | Automatic in VirtualGPIOModel | Manual in testbench |

### When to Use Each

**Use VirtualGPIO When**:
- Need multiple status bits
- Want to track test phases
- Need data exchange between firmware and test
- Want automatic logging of firmware writes

**Use Management GPIO When**:
- Simple pass/fail indication sufficient
- Minimal testbench complexity desired
- Standard caravel test pattern preferred
- Single bit status is enough

## Best Practice: Use Both

**Optimal Pattern**:
```c
// Use VirtualGPIO for detailed status
*VGPIO = 0x0001;  // Phase 1
// ... test phase 1 ...
*VGPIO = 0x0002;  // Phase 2
// ... test phase 2 ...

// Use Management GPIO for final pass/fail (standard pattern)
if (all_tests_passed) {
    ManagmentGpio_write(1);  // Signal success
    *VGPIO = 0x00FF;         // Detailed status
} else {
    ManagmentGpio_write(0);  // Signal failure
    *VGPIO = 0x0000;         // Detailed status
}
```

**Python Test**:
```python
# Monitor detailed progress with VirtualGPIO
virtual_gpio = VirtualGPIOModel(caravelEnv)
virtual_gpio.start()

# Still use @report_test to handle overall pass/fail
# @report_test checks management GPIO automatically
```

## Example: Enhanced I2C Test

### Firmware with VirtualGPIO
```c
#define VGPIO ((volatile uint32_t*)0x30FFFFFC)
#define STATUS_INIT_DONE    0x0001
#define STATUS_SLAVE_PASS   0x0002
#define STATUS_EEPROM_PASS  0x0004
#define STATUS_ALL_PASS     0x00FF

void main() {
    ManagmentGpio_outputEnable();
    enableHkSpi(0);
    
    GPIOs_configure(5, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
    GPIOs_configure(6, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
    GPIOs_loadConfigs();
    
    i2c_init(62);
    *VGPIO = STATUS_INIT_DONE;
    
    // Test simple slave
    i2c_write_byte(0x50, 0, 0xAA);
    uint8_t val = i2c_read_byte(0x50, 0);
    if (val == 0xAA) {
        *VGPIO = STATUS_SLAVE_PASS;
    } else {
        return;  // Fail
    }
    
    // Test EEPROM
    i2c_eeprom_write(0x50, 0x0000, 0x12);
    uint8_t eeprom_val = i2c_eeprom_read(0x50, 0x0000);
    if (eeprom_val == 0x12) {
        *VGPIO = STATUS_SLAVE_PASS | STATUS_EEPROM_PASS;
    } else {
        return;  // Fail
    }
    
    // All passed
    *VGPIO = STATUS_ALL_PASS;
    ManagmentGpio_write(1);
}
```

### Python Test with VirtualGPIO
```python
@cocotb.test()
@report_test
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    virtual_gpio = VirtualGPIOModel(caravelEnv)
    virtual_gpio.start()
    
    cocotb.log.info("[TEST] Waiting for I2C init...")
    await virtual_gpio.wait_output(0x0001)
    cocotb.log.info("[TEST] I2C initialized")
    
    cocotb.log.info("[TEST] Waiting for simple slave test...")
    await virtual_gpio.wait_output(0x0002)
    cocotb.log.info("[TEST] Simple slave test passed")
    
    cocotb.log.info("[TEST] Waiting for EEPROM test...")
    await virtual_gpio.wait_output(0x0006)  # Both bits set
    cocotb.log.info("[TEST] EEPROM test passed")
    
    cocotb.log.info("[TEST] Waiting for final status...")
    # @report_test will handle final pass/fail automatically
```

## Debugging with VirtualGPIOModel

### Enable Detailed Logging
VirtualGPIOModel automatically logs all transactions:
```
[VirtualGPIOModel] initialized with address: 0x30FFFFFC
[VirtualGPIOModel] Starting Wishbone interface monitoring...
[VirtualGPIOModel] Write OUTPUT[15:0]: 0x0001
[VirtualGPIOModel] Write OUTPUT[15:0]: 0x0002
```

### Waveform Signals
Monitor these signals in GTKWave:
- `uut.chip_core.mprj.wbs_adr_i` - Wishbone address
- `uut.chip_core.mprj.wbs_dat_i` - Wishbone write data
- `uut.chip_core.mprj.wbs_dat_o` - Wishbone read data
- `uut.chip_core.mprj.wbs_we_i` - Write enable

Look for transactions to address `0x30FFFFFC`.

## Summary

✅ **VirtualGPIOModel Provides**:
- Memory-mapped GPIO at 0x30FFFFFC
- 16-bit output (firmware → testbench)
- 16-bit input (testbench → firmware)
- Python API for monitoring and control
- Automatic logging of all transactions

✅ **Use Cases**:
- Multi-phase test status tracking
- Data exchange firmware ↔ testbench
- Detailed pass/fail reporting
- Dynamic test vector generation

✅ **Integration**:
- Works alongside management GPIO
- Compatible with @report_test decorator
- Non-intrusive (standard Wishbone)
- Easy to add to existing tests

The VirtualGPIOModel is a powerful tool for creating sophisticated, observable, and debuggable firmware-testbench interactions in caravel-cocotb tests!
