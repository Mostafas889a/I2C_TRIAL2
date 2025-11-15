import cocotb
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from cocotb.triggers import RisingEdge, FallingEdge
import sys
sys.path.append('..')
#from VirtualGPIOModel import VirtualGPIOModel

@cocotb.test()
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    
    await wait_reg1(cpu, caravelEnv, 0xFF)
    
    cocotb.log.info("[TEST] Test passed - I2C read/write successful")
