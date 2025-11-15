import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
import os

@cocotb.test()
async def i2c_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=561831)
    
    cocotb.log.info("[TEST] Starting I2C master-slave communication test")
    
    await wait_reg1(cpu, caravelEnv, 0xFF)
    
    cocotb.log.info("[TEST] Test passed - I2C read/write successful")
