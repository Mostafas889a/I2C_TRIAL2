from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
from caravel_cocotb.caravel_interfaces import VirtualGPIOModel
import cocotb
from cocotb.triggers import RisingEdge

@cocotb.test()
@report_test
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    cocotb.log.info("[TEST] Firmware will test both simple slave and M24AA64 EEPROM")
    
    virtual_gpio = VirtualGPIOModel(caravelEnv)
    virtual_gpio.start()
    await virtual_gpio.wait_output(1)

    cocotb.log.info("[TEST] VirtualGPIOModel started - monitoring GPIO at 0x30FFFFFC")
    cocotb.log.info("[TEST] Phase 1: Simple slave (4 registers)")
    cocotb.log.info("[TEST] Phase 2: EEPROM slave (8KB memory)")
    cocotb.log.info("[TEST] Waiting for firmware to complete...")
    cocotb.log.info("[TEST] - GPIO toggles indicate phase completion")
    cocotb.log.info("[TEST] - Final GPIO=1 indicates all tests passed")
