#ifndef I2C_TEST_H
#define I2C_TEST_H

#include <stdint.h>

#define I2C_BASE_ADDR 0x30000000

#define I2C_REG_PRESCALE_LOW   (I2C_BASE_ADDR + 0x00)
#define I2C_REG_PRESCALE_HIGH  (I2C_BASE_ADDR + 0x04)
#define I2C_REG_CONTROL        (I2C_BASE_ADDR + 0x08)
#define I2C_REG_DATA           (I2C_BASE_ADDR + 0x0C)
#define I2C_REG_CMD_STATUS     (I2C_BASE_ADDR + 0x10)

#define I2C_CTRL_EN            (1 << 7)
#define I2C_CTRL_IEN           (1 << 6)

#define I2C_CMD_START          (1 << 7)
#define I2C_CMD_STOP           (1 << 6)
#define I2C_CMD_READ           (1 << 5)
#define I2C_CMD_WRITE          (1 << 4)
#define I2C_CMD_ACK            (1 << 3)
#define I2C_CMD_IACK           (1 << 0)

#define I2C_STAT_RXACK         (1 << 7)
#define I2C_STAT_BUSY          (1 << 6)
#define I2C_STAT_AL            (1 << 5)
#define I2C_STAT_TIP           (1 << 1)
#define I2C_STAT_IF            (1 << 0)

#define I2C_SLAVE_ADDR 0x50

static inline void reg_write(uint32_t addr, uint32_t value) {
    *((volatile uint32_t*)addr) = value;
}

static inline uint32_t reg_read(uint32_t addr) {
    return *((volatile uint32_t*)addr);
}

static inline void i2c_init(uint32_t prescale) {
    reg_write(I2C_REG_PRESCALE_LOW, prescale & 0xFF);
    reg_write(I2C_REG_PRESCALE_HIGH, (prescale >> 8) & 0xFF);
    reg_write(I2C_REG_CONTROL, I2C_CTRL_EN);
}

static inline void i2c_wait_tip() {
    while (reg_read(I2C_REG_CMD_STATUS) & I2C_STAT_TIP);
}

static inline uint8_t i2c_get_ack() {
    return (reg_read(I2C_REG_CMD_STATUS) & I2C_STAT_RXACK) ? 0 : 1;
}

static inline void i2c_write_byte(uint8_t slave_addr, uint8_t reg_addr, uint8_t data) {
    reg_write(I2C_REG_DATA, (slave_addr << 1) | 0);
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_tip();
    
    reg_write(I2C_REG_DATA, reg_addr);
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_WRITE);
    i2c_wait_tip();
    
    reg_write(I2C_REG_DATA, data);
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_WRITE | I2C_CMD_STOP);
    i2c_wait_tip();
}

static inline uint8_t i2c_read_byte(uint8_t slave_addr, uint8_t reg_addr) {
    reg_write(I2C_REG_DATA, (slave_addr << 1) | 0);
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_tip();
    
    reg_write(I2C_REG_DATA, reg_addr);
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_WRITE);
    i2c_wait_tip();
    
    reg_write(I2C_REG_DATA, (slave_addr << 1) | 1);
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_START | I2C_CMD_WRITE);
    i2c_wait_tip();
    
    reg_write(I2C_REG_CMD_STATUS, I2C_CMD_READ | I2C_CMD_ACK | I2C_CMD_STOP);
    i2c_wait_tip();
    
    return (uint8_t)reg_read(I2C_REG_DATA);
}

#endif
