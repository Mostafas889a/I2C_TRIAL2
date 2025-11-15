# Register Map

## Address Space
- User project base address: `0x3000_0000`
- I2C Master peripheral: `0x3000_0000` - `0x3000_FFFF` (64KB window)

## I2C Master Registers (EF_I2C)

The I2C master controller uses the EF_I2C IP v1.1.0 register interface.

### Register Summary

| Offset | Name | Type | Reset | Description |
|--------|------|------|-------|-------------|
| 0x00 | PRESCALE_LOW | RW | 0x00 | Clock prescaler low byte |
| 0x04 | PRESCALE_HIGH | RW | 0x00 | Clock prescaler high byte |
| 0x08 | CONTROL | RW | 0x00 | Control register |
| 0x0C | DATA | RW | 0x00 | Transmit/Receive data |
| 0x10 | COMMAND | WO | 0x00 | Command register |
| 0x10 | STATUS | RO | 0x00 | Status register (same offset as COMMAND) |

### Register Details

#### PRESCALE_LOW (0x00) - RW
| Bits | Field | Description |
|------|-------|-------------|
| 7:0 | PRESCALE[7:0] | Clock prescaler low byte |

#### PRESCALE_HIGH (0x04) - RW
| Bits | Field | Description |
|------|-------|-------------|
| 7:0 | PRESCALE[15:8] | Clock prescaler high byte |

**Prescaler Calculation:**
```
SCL_freq = wb_clk_i / (5 * (PRESCALE + 1))
```

#### CONTROL (0x08) - RW
| Bits | Field | Reset | Description |
|------|-------|-------|-------------|
| 7 | EN | 0 | I2C core enable (1=enabled) |
| 6 | IEN | 0 | Interrupt enable (1=enabled) |
| 5:0 | Reserved | 0 | Reserved, write 0 |

#### DATA (0x0C) - RW
| Bits | Field | Description |
|------|-------|-------------|
| 7:0 | DATA | Transmit data (write) / Receive data (read) |

#### COMMAND (0x10) - WO
| Bits | Field | Description |
|------|-------|-------------|
| 7 | STA | Generate START condition |
| 6 | STO | Generate STOP condition |
| 5 | RD | Read from slave |
| 4 | WR | Write to slave |
| 3 | ACK | ACK value to send (0=ACK, 1=NACK) |
| 2:0 | Reserved | Write 0 |

#### STATUS (0x10) - RO
| Bits | Field | Description |
|------|-------|-------------|
| 7 | RxACK | Received ACK from slave (0=ACK, 1=NACK) |
| 6 | BUSY | I2C bus busy |
| 5 | AL | Arbitration lost |
| 4:2 | Reserved | Reserved |
| 1 | TIP | Transfer in progress |
| 0 | IF | Interrupt flag (cleared by reading STATUS) |

## I2C Slave Registers (Test Module)

The I2C slave is a simple test module for verification purposes with a small register file.

### Register Summary

| I2C Address | Offset | Name | Type | Description |
|-------------|--------|------|------|-------------|
| 0x50 | 0x00 | DATA0 | RW | Test data register 0 |
| 0x50 | 0x01 | DATA1 | RW | Test data register 1 |
| 0x50 | 0x02 | DATA2 | RW | Test data register 2 |
| 0x50 | 0x03 | DATA3 | RW | Test data register 3 |

All registers are 8-bit read/write and reset to 0x00.

## Usage Examples

### I2C Master Initialization
```c
#define I2C_BASE 0x30000000
#define PRESCALE_LOW  (I2C_BASE + 0x00)
#define PRESCALE_HIGH (I2C_BASE + 0x04)
#define CONTROL       (I2C_BASE + 0x08)
#define DATA          (I2C_BASE + 0x0C)
#define COMMAND       (I2C_BASE + 0x10)
#define STATUS        (I2C_BASE + 0x10)

// Initialize for 100kHz with 25MHz clock
// SCL = 25MHz / (5 * (124 + 1)) = 40kHz (conservative)
*(volatile uint32_t*)PRESCALE_LOW = 124;
*(volatile uint32_t*)PRESCALE_HIGH = 0;
*(volatile uint32_t*)CONTROL = 0x80;  // Enable core
```

### I2C Write Transaction
```c
// Write 0xAA to slave address 0x50, register 0x00
*(volatile uint32_t*)DATA = 0xA0;     // Slave address 0x50, write
*(volatile uint32_t*)COMMAND = 0x90;  // START + WRITE
while(*(volatile uint32_t*)STATUS & 0x02);  // Wait for TIP=0

*(volatile uint32_t*)DATA = 0x00;     // Register address
*(volatile uint32_t*)COMMAND = 0x10;  // WRITE
while(*(volatile uint32_t*)STATUS & 0x02);

*(volatile uint32_t*)DATA = 0xAA;     // Data
*(volatile uint32_t*)COMMAND = 0x50;  // WRITE + STOP
while(*(volatile uint32_t*)STATUS & 0x02);
```

### I2C Read Transaction
```c
// Read from slave address 0x50, register 0x00
*(volatile uint32_t*)DATA = 0xA0;     // Slave address, write
*(volatile uint32_t*)COMMAND = 0x90;  // START + WRITE
while(*(volatile uint32_t*)STATUS & 0x02);

*(volatile uint32_t*)DATA = 0x00;     // Register address
*(volatile uint32_t*)COMMAND = 0x10;  // WRITE
while(*(volatile uint32_t*)STATUS & 0x02);

*(volatile uint32_t*)DATA = 0xA1;     // Slave address, read
*(volatile uint32_t*)COMMAND = 0x90;  // START + WRITE
while(*(volatile uint32_t*)STATUS & 0x02);

*(volatile uint32_t*)COMMAND = 0x68;  // READ + NACK + STOP
while(*(volatile uint32_t*)STATUS & 0x02);

uint8_t data = *(volatile uint32_t*)DATA & 0xFF;
```

## Notes
- All registers are 32-bit aligned (word access)
- Byte lane selection via `wbs_sel_i` is supported
- Invalid address accesses return `0xDEADBEEF` on reads
- Invalid writes are acknowledged but discarded
