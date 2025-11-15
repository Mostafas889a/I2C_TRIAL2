# Register Map

## Address Space
- User project base address: `0x3000_0000`
- I2C Master peripheral: `0x3000_0000` - `0x3000_FFFF` (64KB window)

## I2C Master Registers (CF_I2C)

The I2C master controller uses the CF_I2C IP v2.0.0 FIFO-based register interface.

### Register Summary

| Offset | Name | Type | Reset | Description |
|--------|------|------|-------|-------------|
| 0x0000 | STATUS | RO | 0x00000000 | Status register (FIFO status, busy, miss_ack) |
| 0x0004 | COMMAND | WO | 0x00000000 | Command register (address, start, read, write, stop) |
| 0x0008 | DATA | RW | 0x00000000 | Data register (data, data_valid, data_last) |
| 0x000C | PR | WO | 0x00000000 | Prescaler: prescale = Fclk / (FI2Cclk * 4) |
| 0xFF00 | IM | WO | 0x00000000 | Interrupt Mask Register |
| 0xFF04 | MIS | RO | 0x00000000 | Masked Interrupt Status |
| 0xFF08 | RIS | RO | 0x00000000 | Raw Interrupt Status |
| 0xFF0C | IC | WO | 0x00000000 | Interrupt Clear Register |
| 0xFF10 | GCLK | WO | 0x00000000 | Gated Clock Enable |

### Register Details

#### STATUS (0x0000) - RO
| Bits | Field | Description |
|------|-------|-------------|
| 0 | busy | High when module is performing an I2C operation |
| 1 | bus_cont | High when module has control of active bus |
| 2 | bus_act | High when bus is active |
| 3 | miss_ack | Set high when an ACK pulse from a slave device is not seen (W1C) |
| 8 | cmd_empty | Command FIFO empty |
| 9 | cmd_full | Command FIFO full |
| 10 | cmd_ovf | Command FIFO overflow (W1C) |
| 11 | wr_empty | Write data FIFO empty |
| 12 | wr_full | Write data FIFO full |
| 13 | wr_ovf | Write data FIFO overflow (W1C) |
| 14 | rd_empty | Read data FIFO is empty |
| 15 | rd_full | Read data FIFO is full |

#### COMMAND (0x0004) - WO
| Bits | Field | Description |
|------|-------|-------------|
| 6:0 | cmd_address | I2C address for command |
| 8 | cmd_start | Set high to issue I2C start (write to push on command FIFO) |
| 9 | cmd_read | Set high to start read (write to push on command FIFO) |
| 10 | cmd_write | Set high to start write (write to push on command FIFO) |
| 11 | cmd_write_multiple | Set high to start block write (write to push on command FIFO) |
| 12 | cmd_stop | Set high to issue I2C stop (write to push on command FIFO) |

Note: Setting multiple command bits is allowed. Start or repeated start will be issued first, followed by read or write, followed by stop. Setting read and write at the same time is not allowed and will be ignored.

#### DATA (0x0008) - RW
| Bits | Field | Description |
|------|-------|-------------|
| 7:0 | data | Data byte to write or read data byte |
| 8 | data_valid | Data valid flag |
| 9 | data_last | Data last flag (for block transfers) |

#### PR (0x000C) - WO
| Bits | Field | Description |
|------|-------|-------------|
| 15:0 | prescale | Clock prescaler: prescale = Fclk / (FI2Cclk * 4) |

For example, with 25 MHz system clock and desired 100 kHz I2C clock:
prescale = 25,000,000 / (100,000 * 4) = 62.5 ≈ 62

## I2C Slave Test Module Registers

The I2C slave test module has 4 registers at slave address 0x50:

| Register | Offset | Type | Reset | Description |
|----------|--------|------|-------|-------------|
| REG0 | 0x00 | RW | 0x00 | Test register 0 |
| REG1 | 0x01 | RW | 0x00 | Test register 1 |
| REG2 | 0x02 | RW | 0x00 | Test register 2 |
| REG3 | 0x03 | RW | 0x00 | Test register 3 |

## Usage Examples

### Initialization (C code)
```c
// Set prescaler for 100 kHz I2C (25 MHz system clock)
reg_write(I2C_BASE + 0x0C, 62);
```

### Write Transaction (C code)
```c
// Write 0xAA to slave 0x50 register 0x01
// 1. Write slave address + write bit to DATA register
reg_write(I2C_BASE + 0x08, 0xAA);  // Write data to FIFO

// 2. Issue START + WRITE command with slave address
reg_write(I2C_BASE + 0x04, (0x50) | (1 << 8) | (1 << 10));  // address, START, WRITE

// 3. Wait for completion (poll STATUS.busy or use interrupt)
while (reg_read(I2C_BASE + 0x00) & 0x01);  // Wait while busy

// 4. Write register address
reg_write(I2C_BASE + 0x08, 0x01);  // Register address
reg_write(I2C_BASE + 0x04, (0x50) | (1 << 10));  // WRITE
while (reg_read(I2C_BASE + 0x00) & 0x01);

// 5. Write data and issue STOP
reg_write(I2C_BASE + 0x08, 0xAA);  // Data
reg_write(I2C_BASE + 0x04, (0x50) | (1 << 10) | (1 << 12));  // WRITE + STOP
while (reg_read(I2C_BASE + 0x00) & 0x01);
```

### Read Transaction (C code)
```c
// Read from slave 0x50 register 0x01
// 1. Write slave address + register address
reg_write(I2C_BASE + 0x08, 0x01);  // Register address
reg_write(I2C_BASE + 0x04, (0x50) | (1 << 8) | (1 << 10));  // START + WRITE

// 2. Issue repeated START with READ command
reg_write(I2C_BASE + 0x04, (0x50) | (1 << 8) | (1 << 9) | (1 << 12));  // START + READ + STOP

// 3. Wait and read data
while (reg_read(I2C_BASE + 0x00) & 0x01);
uint8_t data = reg_read(I2C_BASE + 0x08) & 0xFF;
```
