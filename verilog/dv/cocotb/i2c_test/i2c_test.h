#ifndef I2C_TEST_H
#define I2C_TEST_H

#include <stdint.h>

#define I2C_BASE_ADDR 0x30000000

#define I2C_REG_STATUS    (I2C_BASE_ADDR + 0x00)
#define I2C_REG_COMMAND   (I2C_BASE_ADDR + 0x04)
#define I2C_REG_DATA      (I2C_BASE_ADDR + 0x08)
#define I2C_REG_PR        (I2C_BASE_ADDR + 0x0C)
#define I2C_REG_IM        (I2C_BASE_ADDR + 0xFF00)
#define I2C_REG_MIS       (I2C_BASE_ADDR + 0xFF04)
#define I2C_REG_RIS       (I2C_BASE_ADDR + 0xFF08)
#define I2C_REG_IC        (I2C_BASE_ADDR + 0xFF0C)
#define I2C_REG_GCLK      (I2C_BASE_ADDR + 0xFF10)

#define I2C_STAT_BUSY         (1 << 0)
#define I2C_STAT_BUS_CONT     (1 << 1)
#define I2C_STAT_BUS_ACT      (1 << 2)
#define I2C_STAT_MISS_ACK     (1 << 3)
#define I2C_STAT_CMD_EMPTY    (1 << 8)
#define I2C_STAT_CMD_FULL     (1 << 9)
#define I2C_STAT_WR_EMPTY     (1 << 11)
#define I2C_STAT_RD_EMPTY     (1 << 14)

#define I2C_CMD_START         (1 << 8)
#define I2C_CMD_READ          (1 << 9)
#define I2C_CMD_WRITE         (1 << 10)
#define I2C_CMD_WRITE_MULT    (1 << 11)
#define I2C_CMD_STOP          (1 << 12)

#define I2C_SLAVE_ADDR 0x50

static inline void reg_write(uint32_t addr, uint32_t value) {
    *((volatile uint32_t*)addr) = value;
}

static inline uint32_t reg_read(uint32_t addr) {
    return *((volatile uint32_t*)addr);
}

static inline void i2c_init(uint32_t prescale) {
    reg_write(I2C_REG_PR, prescale);
}

static inline void i2c_wait_busy() {
    while (reg_read(I2C_REG_STATUS) & I2C_STAT_BUSY);
}

static inline void i2c_write_byte(uint8_t slave_addr, uint8_t reg_addr, uint8_t data) {
    reg_write(I2C_REG_DATA, reg_addr);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    reg_write(I2C_REG_DATA, data);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_WRITE | I2C_CMD_STOP);
    i2c_wait_busy();
}

static inline uint8_t i2c_read_byte(uint8_t slave_addr, uint8_t reg_addr) {
    reg_write(I2C_REG_DATA, reg_addr);
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_busy();
    
    reg_write(I2C_REG_COMMAND, slave_addr | I2C_CMD_START | I2C_CMD_READ | I2C_CMD_STOP);
    i2c_wait_busy();
    
    while (reg_read(I2C_REG_STATUS) & I2C_STAT_RD_EMPTY);
    
    return (uint8_t)(reg_read(I2C_REG_DATA) & 0xFF);
}

#endif
