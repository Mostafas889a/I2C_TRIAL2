#include <firmware_apis.h>
#include "i2c_test.h"

#define VGPIO_REG_ADDR 0x30FFFFFC

void vgpio_write_output(uint16_t value)
{
    volatile uint32_t *vgpio_reg = (volatile uint32_t *)VGPIO_REG_ADDR;
    uint32_t reg_val = *vgpio_reg;
    reg_val = (reg_val & 0xFFFF0000) | (value & 0xFFFF);
    *vgpio_reg = reg_val;
}

uint16_t vgpio_read_input(void)
{
    volatile uint32_t *vgpio_reg = (volatile uint32_t *)VGPIO_REG_ADDR;
    uint32_t reg_val = *vgpio_reg;
    return (uint16_t)((reg_val >> 16) & 0xFFFF);
}

void vgpio_wait_val(uint16_t val)
{
    while (vgpio_read_input() != val);
}

void main() {
    ManagmentGpio_outputEnable();
    
    enableHkSpi(0);
    
    GPIOs_configure(5, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
    GPIOs_configure(6, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
    GPIOs_loadConfigs();
    vgpio_write_output(1);
    
    
    i2c_init(62);
    
    
    i2c_write_byte(I2C_SLAVE_ADDR, 0, 0xAA);
    i2c_write_byte(I2C_SLAVE_ADDR, 1, 0x55);
    i2c_write_byte(I2C_SLAVE_ADDR, 2, 0xDE);
    i2c_write_byte(I2C_SLAVE_ADDR, 3, 0xAD);
    vgpio_write_output(1);

    
    uint8_t val0 = i2c_read_byte(I2C_SLAVE_ADDR, 0);
    uint8_t val1 = i2c_read_byte(I2C_SLAVE_ADDR, 1);
    uint8_t val2 = i2c_read_byte(I2C_SLAVE_ADDR, 2);
    uint8_t val3 = i2c_read_byte(I2C_SLAVE_ADDR, 3);
    
    
    if (val0 == 0xAA && val1 == 0x55 && val2 == 0xDE && val3 == 0xAD) {
        ManagmentGpio_write(1);
    } else {
        return;
    }
    
    
    i2c_eeprom_write(I2C_EEPROM_ADDR, 0x0000, 0x12);
    i2c_eeprom_write(I2C_EEPROM_ADDR, 0x0001, 0x34);
    i2c_eeprom_write(I2C_EEPROM_ADDR, 0x0010, 0x56);
    i2c_eeprom_write(I2C_EEPROM_ADDR, 0x0100, 0x78);
    
    
    uint8_t eeprom_val0 = i2c_eeprom_read(I2C_EEPROM_ADDR, 0x0000);
    uint8_t eeprom_val1 = i2c_eeprom_read(I2C_EEPROM_ADDR, 0x0001);
    uint8_t eeprom_val2 = i2c_eeprom_read(I2C_EEPROM_ADDR, 0x0010);
    uint8_t eeprom_val3 = i2c_eeprom_read(I2C_EEPROM_ADDR, 0x0100);
    
    
    if (eeprom_val0 == 0x12 && eeprom_val1 == 0x34 && eeprom_val2 == 0x56 && eeprom_val3 == 0x78) {
        ManagmentGpio_write(1);
    }
    
    return;
}
