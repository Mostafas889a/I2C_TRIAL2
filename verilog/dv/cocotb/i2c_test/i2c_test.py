from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb

@cocotb.test()
@report_test
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    cocotb.log.info("[TEST] Firmware will test both simple slave and M24AA64 EEPROM")
    cocotb.log.info("[TEST] Phase 1: Simple slave (4 registers)")
    cocotb.log.info("[TEST] Phase 2: EEPROM slave (8KB memory)")
    cocotb.log.info("[TEST] Management GPIO will toggle to indicate progress")
    cocotb.log.info("[TEST] Final GPIO=1 indicates all tests passed")
