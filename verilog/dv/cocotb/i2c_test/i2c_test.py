from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
from caravel_cocotb.caravel_interfaces import VirtualGPIOModel
import cocotb
from cocotb.triggers import RisingEdge
from i2c_slave import i2c_slave

@cocotb.test()
@report_test
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    caravelEnv.drive_gpio_in((9,8),0)
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    cocotb.log.info("[TEST] Firmware will test both simple slave and M24AA64 EEPROM")
    
    virtual_gpio = VirtualGPIOModel(caravelEnv)
    virtual_gpio.start()
    await cocotb.start(i2c_slave())

    await virtual_gpio.wait_output(1)
    await virtual_gpio.wait_output(2)

