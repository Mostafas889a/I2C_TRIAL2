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

## M24AA64 EEPROM (Test Slave)

The M24AA64 is a 64K-bit (8192 x 8) I2C EEPROM with 13-bit addressing.

### I2C Device Address
- **Base Address**: 0b1010 (A[2:0] configurable via pins)
- **Device Address**: 0x50 (with A2=A1=A0=0)
- **Write Address**: 0xA0 (0x50 << 1 | 0)
- **Read Address**: 0xA1 (0x50 << 1 | 1)

### Memory Organization
- **Capacity**: 8192 bytes (8KB)
- **Page Size**: 32 bytes
- **Address Range**: 0x0000 - 0x1FFF (13-bit address)
- **Addressing**: 2-byte address (high byte + low byte)

### Write Operation Sequence
1. Send START condition
2. Send device address + WRITE bit (0xA0)
3. Wait for ACK
4. Send address high byte (bits 12:8 in lower 5 bits)
5. Wait for ACK
6. Send address low byte (bits 7:0)
7. Wait for ACK
8. Send data byte(s) - up to 32 bytes per page
9. Wait for ACK after each byte
10. Send STOP condition
11. Wait for write cycle time (tWC = 5ms max)

### Read Operation Sequence
1. Send START condition
2. Send device address + WRITE bit (0xA0)
3. Wait for ACK
4. Send address high byte
5. Wait for ACK
6. Send address low byte
7. Wait for ACK
8. Send repeated START
9. Send device address + READ bit (0xA1)
10. Wait for ACK
11. Read data byte(s)
12. Send ACK (for continued read) or NACK (for last byte)
13. Send STOP condition

### Timing Parameters
- **Clock Frequency**: Up to 400 kHz (Fast Mode), 100 kHz (Standard Mode)
- **Write Cycle Time (tWC)**: 5 ms maximum
- **SCL to SDA Output Delay (tAA)**: 900 ns @ 2.5V-5.5V, 3500 ns @ 1.7V-2.5V

### C API Examples

#### Write Single Byte to EEPROM
```c
void i2c_eeprom_write(uint8_t slave_addr, uint16_t addr, uint8_t data) {
    // Write address high byte
    reg_write(I2C_REG_DATA, (addr >> 8) & 0xFF);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    // Write address low byte
    reg_write(I2C_REG_DATA, addr & 0xFF);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    // Write data byte and STOP
    reg_write(I2C_REG_DATA, data);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE | I2C_CMD_STOP);
    i2c_wait_busy();
    
    // Wait for write cycle (5ms)
    // In real hardware, poll or wait
}
```

#### Read Single Byte from EEPROM
```c
uint8_t i2c_eeprom_read(uint8_t slave_addr, uint16_t addr) {
    // Write address
    reg_write(I2C_REG_DATA, (addr >> 8) & 0xFF);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    reg_write(I2C_REG_DATA, addr & 0xFF);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    // Repeated START + READ + STOP
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_READ | I2C_CMD_STOP);
    i2c_wait_busy();
    
    // Wait for data in read FIFO
    while (reg_read(I2C_REG_STATUS) & I2C_STAT_RD_EMPTY);
    
    return (uint8_t)(reg_read(I2C_REG_DATA) & 0xFF);
}
```

### Page Write Operation (1-32 bytes)
```c
void i2c_eeprom_page_write(uint8_t slave_addr, uint16_t addr, uint8_t *data, uint8_t len) {
    // Write address
    reg_write(I2C_REG_DATA, (addr >> 8) & 0xFF);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    reg_write(I2C_REG_DATA, addr & 0xFF);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    // Write data bytes (up to 32)
    for (int i = 0; i < len && i < 32; i++) {
        reg_write(I2C_REG_DATA, data[i]);
        if (i == len - 1) {
            reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE | I2C_CMD_STOP);
        } else {
            reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE);
        }
        i2c_wait_busy();
    }
}
```

### Notes
- Page writes must stay within a single 32-byte page boundary
- Writing across page boundaries will wrap within the page
- Write cycle time must complete before next operation
- EEPROM model is for simulation only (testbench fixture)
