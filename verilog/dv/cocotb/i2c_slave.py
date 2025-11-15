import cocotb
from cocotb.triggers import RisingEdge, FallingEdge


class i2c_slave:
    def __init__(self, scl_line, sda_line, sda_drive, mem=None):
        self.scl = scl_line
        self.sda_in = sda_line
        self.sda_out = sda_drive
        self.storage = mem if mem is not None else {}

    # ---------- I2C Protocol Helpers ----------

    async def collect_bits(self, width):
        """Read multiple bits on clock edges."""
        result = ""
        for _ in range(width):
            await RisingEdge(self.scl)
            result += self.sda_in.value.binstr
        cocotb.log.debug(f"[I2C Slave] Captured bits: {result}")
        return int(result, 2)

    def reg_write(self, addr, value):
        cocotb.log.info(f"[I2C Slave] WR: Address {hex(addr)} <= {hex(value)}")
        self.storage[addr] = value

    def reg_read(self, addr):
        if addr not in self.storage:
            raise RuntimeError("Unknown register access")
        val = self.storage[addr]
        cocotb.log.info(f"[I2C Slave] RD: Address {hex(addr)} -> {hex(val)}")
        return val

    async def transmit_byte(self, value):
        """Send a full byte MSB-first."""
        data_bits = f"{value:08b}"
        cocotb.log.info(f"[I2C Slave] Sending byte: {data_bits}")

        for bit in data_bits:
            cocotb.log.debug(f"[I2C Slave] → {bit}")
            self.sda_out.value = bit
            await FallingEdge(self.scl)

    # ---------- Main protocol handling ----------

    async def run(self):
        """Loop forever until stop condition ends frame."""
        while True:
            task = await cocotb.start(self.handle_transaction())
            await self.monitor_stop()
            task.kill()
            cocotb.log.info("[I2C Slave] STOP detected → transaction closed.")

    async def handle_transaction(self):
        """Handle a single START–STOP communication frame."""
        # wait for START
        while True:
            cocotb.log.info("[I2C Slave] Wait SDA falling")
            await FallingEdge(self.sda_in) # wait for SDA falling
            cocotb.log.info("[I2C Slave] Detected SDA falling")
            if self.scl.value.binstr == '1':
                cocotb.log.info("[I2C Slave] START detected")
                break

        # read slave address (7 bits)
        address = await self.collect_bits(7)
        cocotb.log.info(f"[I2C Slave] Received Address: {hex(address)}")

        # read R/W bit
        rw_bit = await self.collect_bits(1)
        cocotb.log.info(f"[I2C Slave] RW bit: {rw_bit}")

        # Acknowledge
        await FallingEdge(self.scl)
        self.sda_out.value = 0
        await FallingEdge(self.scl)
        cocotb.log.info("[I2C Slave] ACK sent")

        # Perform operation
        if rw_bit == 0:
            data_in = await self.collect_bits(8)
            self.reg_write(address, data_in)
        else:
            outgoing = self.reg_read(address)
            await self.transmit_byte(outgoing)

        # Send NACK to end transfer
        await FallingEdge(self.scl)
        self.sda_out.value = 1
        await FallingEdge(self.scl)
        cocotb.log.info("[I2C Slave] NACK sent")

    # ---------- Stop condition detection ----------

    async def track_last_clk_edge(self):
        while True:
            await RisingEdge(self.scl)
            self._last_edge = cocotb.utils.get_sim_time("ns")

    async def monitor_stop(self):
        await cocotb.start(self.track_last_clk_edge())
        await RisingEdge(self.scl)

        while True:
            await RisingEdge(self.sda_in)
            now = cocotb.utils.get_sim_time("ns")
            if self.scl.value.binstr == '1' and now > getattr(self, "_last_edge", 0):
                cocotb.log.debug("[I2C Slave] STOP condition confirmed")
                break
