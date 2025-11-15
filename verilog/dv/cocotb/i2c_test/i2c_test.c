#include <firmware_apis.h>
#include "CF_I2C.h"

#define VGPIO_REG_ADDR 0x30FFFFFC
#define I2C_BASE 0x30000000
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

void i2c_write_address(char adr, char data){
    CF_I2C_writeDataToWriteFIFO(I2C_BASE, data);
    CF_I2C_setCommandReg(I2C_BASE, adr);
    CF_I2C_sendStopCommand(I2C_BASE);
}
void main() {
    ManagmentGpio_outputEnable();
    
    enableHkSpi(0);
    
    GPIOs_configure(8, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
    GPIOs_configure(9, GPIO_MODE_MGMT_STD_BIDIRECTIONAL);
    GPIOs_loadConfigs();
    User_enableIF();  
    vgpio_write_output(1);
    CF_I2C_setGclkEnable(I2C_BASE, 1);
    CF_I2C_setPrescaler(I2C_BASE,0xF0);
    i2c_write_address(0x5, 0x4D);
    vgpio_write_output(2);
    return;
}
