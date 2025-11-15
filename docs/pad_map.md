# Pad Map

## GPIO Allocation

### I2C Master Signals

| Signal | Direction | GPIO# | Description |
|--------|-----------|-------|-------------|
| scl_o | Output | 5 | I2C clock output |
| scl_i | Input | 5 | I2C clock input (for clock stretching) |
| scl_oe | Output | - | I2C clock output enable (active low in wrapper) |
| sda_o | Output | 6 | I2C data output |
| sda_i | Input | 6 | I2C data input |
| sda_oe | Output | - | I2C data output enable (active low in wrapper) |

**Note**: GPIO 5 and 6 are configured as bidirectional pads for proper I2C open-drain operation.

### I2C Slave Signals (External Test Module)

| Signal | Direction | GPIO# | Description |
|--------|-----------|-------|-------------|
| slave_scl | Input | 5 | Connected to master SCL (shared bus) |
| slave_sda_i | Input | 6 | Connected to master SDA (shared bus) |
| slave_sda_o | Output | 6 | Slave SDA output |
| slave_sda_oe | Output | - | Slave SDA output enable |

**Note**: In physical implementation, the I2C slave can be external to the Caravel chip. For simulation, it's instantiated within the testbench.

## Reserved GPIOs

| GPIO# | Usage | Reason |
|-------|-------|--------|
| 0-4 | Reserved | Caravel system usage, JTAG, etc. |
| 5 | I2C SCL | I2C clock line |
| 6 | I2C SDA | I2C data line |
| 7-37 | Available | Free for future expansion |

## Bidirectional Configuration

Both SCL and SDA lines require bidirectional configuration:

```verilog
// For GPIO 5 (SCL)
assign mprj_io_in[5] = scl_i;
assign mprj_io_out[5] = scl_o;
assign mprj_io_oeb[5] = ~scl_oe;  // Active-low OEB

// For GPIO 6 (SDA)
assign mprj_io_in[6] = sda_i;
assign mprj_io_out[6] = sda_o;
assign mprj_io_oeb[6] = ~sda_oe;  // Active-low OEB
```

## I2C Bus Topology

```
                    VDD
                     |
                    +-+
                    | | Pull-up resistor (external)
                    +-+
                     |
    +----------------+----------------+
    |                                 |
  [SCL]                             [SDA]
    |                                 |
    |    Caravel User Project         |
    |    +------------------+         |
    +----| I2C Master       |         |
    |    | (EF_I2C)        |----+----+
    |    +------------------+         |
    |                                 |
    +----| I2C Slave       |         |
         | (Test Module)   |---------+
         +------------------+

Note: In real implementation, slave would be external.
For cocotb testing, slave is instantiated in testbench.
```

## Configuration Notes

1. **Pull-up Resistors**: I2C requires external pull-up resistors (typically 4.7kΩ to 10kΩ) on both SCL and SDA lines
2. **Open-Drain**: Both master and slave drive '0' or release the line (high-Z)
3. **Bus Arbitration**: Not implemented in this simple design (single master)
4. **Clock Stretching**: Supported by monitoring SCL input while driving
5. **Speed**: Configured via prescaler register, typical 100kHz or 400kHz

## Changing Pad Assignments

To change the GPIO assignments:

1. Edit `verilog/rtl/user_project_wrapper.v`
2. Update the `mprj_io_*[N]` connections
3. Update this documentation
4. Update verification tests to match new pin assignments
5. Rerun synthesis and place & route

Example for moving I2C to GPIO 10 and 11:

```verilog
// Change from GPIO 5,6 to GPIO 10,11
assign mprj_io_in[10] = scl_i;
assign mprj_io_out[10] = scl_o;
assign mprj_io_oeb[10] = ~scl_oe;

assign mprj_io_in[11] = sda_i;
assign mprj_io_out[11] = sda_o;
assign mprj_io_oeb[11] = ~sda_oe;
```

## Power Connections

- **VPWR**: Connected to `vccd1` (1.8V digital supply)
- **VGND**: Connected to `vssd1` (digital ground)

All logic operates at 1.8V with SKY130 process.
