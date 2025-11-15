# Integration Notes

## Overview
This document describes the integration of the EF_I2C IP into a Caravel user project with proper Wishbone B4 interface and custom I2C slave for testing.

## Clock and Reset Architecture

### Clock Domain
- **Single clock domain**: `wb_clk_i` (25 MHz from Caravel)
- No clock domain crossings required
- I2C SCL is generated internally by the EF_I2C core using programmable prescaler

### Reset Strategy
- **Reset signal**: `wb_rst_i` (synchronous, active-high from Caravel)
- All registers reset to known values
- I2C core must be explicitly enabled via CONTROL register after reset

### I2C Clock Generation
```
SCL_frequency = wb_clk_i / (5 * (PRESCALE + 1))

Examples with 25 MHz wb_clk_i:
- 100 kHz: PRESCALE = 49  (25MHz / (5 * 50) = 100kHz)
- 400 kHz: PRESCALE = 11  (25MHz / (5 * 12) = 416.7kHz)
- Conservative: PRESCALE = 124 (25MHz / (5 * 125) = 40kHz)
```

## Wishbone B4 Interface

### Bus Topology
```
Caravel Management SoC
    |
    | Wishbone Classic (32-bit)
    |
user_project_wrapper
    |
user_project
    |
    +-- [Optional: wishbone_bus_splitter for multiple peripherals]
    |
    +-- EF_I2C (with integrated Wishbone wrapper)
```

### Address Mapping
- Base address: `0x3000_0000`
- I2C registers: `0x3000_0000` to `0x3000_0014`
- Unused space: `0x3000_0018` to `0x3000_FFFF`

### Wishbone Signals
| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| wb_clk_i | 1 | Input | System clock (25 MHz) |
| wb_rst_i | 1 | Input | Synchronous reset (active high) |
| wbs_cyc_i | 1 | Input | Bus cycle active |
| wbs_stb_i | 1 | Input | Strobe (address/data valid) |
| wbs_we_i | 1 | Input | Write enable (1=write, 0=read) |
| wbs_sel_i | 4 | Input | Byte lane select |
| wbs_adr_i | 32 | Input | Address bus |
| wbs_dat_i | 32 | Input | Write data bus |
| wbs_dat_o | 32 | Output | Read data bus |
| wbs_ack_o | 1 | Output | Transfer acknowledge |

### Wishbone Timing
- Single-cycle read/write operations
- ACK asserted one cycle after valid transaction
- No wait states for register access
- Supports byte-lane writes via `wbs_sel_i`

### Critical Wishbone Rules
1. **Never gate `wbs_cyc_i`** - route directly to all peripherals
2. **Selection via `wbs_stb_i` only** - use address decode to gate strobe
3. **Always acknowledge** - every valid transaction must be ACKed
4. **Invalid addresses** - return `0xDEADBEEF` on reads, ACK but discard writes

## Interrupt Mapping

The EF_I2C IP provides a single interrupt output:
- **Signal**: `irq` (level-high)
- **Caravel mapping**: Can be connected to `user_irq[0]`, `user_irq[1]`, or `user_irq[2]`
- **Default**: Connected to `user_irq[0]`

### Interrupt Sources
- Transfer complete
- Arbitration lost
- Other I2C events (see EF_I2C documentation)

### Interrupt Control
- Enable via CONTROL[6] (IEN bit)
- Clear by reading STATUS register

## I/O Pad Configuration

### I2C Signals (GPIO 5, 6)
Both SCL and SDA are **bidirectional, open-drain** signals:

```verilog
// SCL - GPIO 5
assign scl_i = mprj_io_in[5];
assign mprj_io_out[5] = scl_o;
assign mprj_io_oeb[5] = ~scl_oe;  // Active-low OEB

// SDA - GPIO 6
assign sda_i = mprj_io_in[6];
assign mprj_io_out[6] = sda_o;
assign mprj_io_oeb[6] = ~sda_oe;  // Active-low OEB
```

### Open-Drain Behavior
- Drive '0': `*_o = 0`, `*_oe = 1` → OEB = 0 (output enabled)
- Release (high-Z): `*_o = 0`, `*_oe = 0` → OEB = 1 (output disabled)
- External pull-ups pull line high when released

## EF_I2C IP Integration

### IP Location
```
/nc/ip/EF_I2C/v1.1.0/
```

### IP Linking
Use ipm_linker to link the IP:

1. Create `ip/link_IPs.json`:
```json
{
  "ips": [
    {
      "name": "EF_I2C",
      "version": "v1.1.0"
    }
  ]
}
```

2. Run linker:
```bash
python /nc/agent_tools/ipm_linker/ipm_linker.py \
  --file /workspace/I2C_TRIAL2/ip/link_IPs.json \
  --project-root /workspace/I2C_TRIAL2
```

### IP Files
- RTL: Check IP documentation for file list
- Wrapper: EF_I2C includes Wishbone wrapper
- Documentation: `/nc/ip/EF_I2C/v1.1.0/README.md`

## I2C Slave Test Module

### Purpose
Simple I2C slave for verification with 4-byte register file.

### Features
- Fixed slave address: 0x50 (7-bit address)
- 4 read/write registers (0x00-0x03)
- Standard I2C protocol (no clock stretching)
- Automatic ACK generation

### Integration
- **For simulation**: Instantiate in testbench, connect to same I2C bus
- **For silicon**: External device on PCB

### Register Access
```
Write: START | 0xA0 | ACK | REG_ADDR | ACK | DATA | ACK | STOP
Read:  START | 0xA0 | ACK | REG_ADDR | ACK | 
       START | 0xA1 | ACK | DATA | NACK | STOP
```

## Simulation and Testing

### Cocotb Tests
Location: `verilog/dv/cocotb/`

Test scenarios:
1. I2C master initialization
2. Single byte write to slave
3. Single byte read from slave
4. Multi-byte write sequence
5. Multi-byte read sequence
6. Register loopback test
7. Interrupt verification
8. Error conditions (NACK, arbitration loss)

### Running Tests
```bash
cd verilog/dv/cocotb
make test_i2c
```

### Design Info
Edit `verilog/dv/cocotb/design_info.yaml` to configure:
- Top module
- Verilog sources
- Test parameters

## Synthesis Notes

### Yosys Script
Location: `syn/yosys.ys`

Key steps:
1. Read SKY130 library
2. Read all RTL files
3. Hierarchy check
4. Synthesize with `-flatten`
5. Check for latches (must be 0)
6. Write netlist

### Linting
```bash
verilator --lint-only --Wno-EOFNEWLINE \
  -Wall -Wpedantic \
  --top-module user_project_wrapper \
  verilog/rtl/*.v
```

## Place & Route (OpenLane)

### Prerequisites
- **Must pass all cocotb tests** before starting PnR
- Ensure no timing violations in synthesis
- Verify no inferred latches

### Macro Hardening Sequence
1. Harden I2C wrapper (if separate macro)
2. Harden user_project (if separate macro)
3. Harden user_project_wrapper (top-level)

### Configuration Tips
- Use timing budgets from signoff.sdc
- Set appropriate die area (minimum 400x400)
- Configure pin order via pin_order.cfg
- Check DRC, LVS, antenna violations

### Common Issues
- **Timing violations**: Adjust prescaler, check clock constraints
- **DRC errors**: Check metal layers, spacing rules
- **LVS errors**: Verify power connections (vccd1/vssd1)

## Power Connections

### User Project Area
- **VPWR**: `vccd1` (1.8V digital)
- **VGND**: `vssd1` (digital ground)

### Power Domain Strategy
- Single power domain
- No power gating
- No special retention requirements

## Design for Test (DFT)

### Scan Chain
Not implemented in this version.

### Observability
- All I2C signals routed to GPIOs
- Wishbone bus accessible via management SoC
- Interrupt output observable

### Debug Features
- Read STATUS register for transfer state
- Monitor SCL/SDA on GPIOs
- Interrupt flag for event detection

## Known Limitations

1. **Single master only**: No multi-master arbitration
2. **No SMBus features**: Standard I2C only
3. **Limited FIFO**: Single-byte data register
4. **No DMA**: All transfers via firmware
5. **Fixed timing**: No runtime clock adjustment during transfer

## Future Enhancements

1. Add multiple I2C peripherals
2. Implement FIFO for bulk transfers
3. Add SMBus/PMBus protocol support
4. DMA integration
5. Multi-master arbitration
6. High-speed mode (3.4 MHz)

## References

1. EF_I2C IP Documentation: `/nc/ip/EF_I2C/v1.1.0/README.md`
2. Caravel User Project Template: `/nc/templates/caravel_user_project/`
3. Wishbone B4 Specification: opencores.org
4. I2C Specification: NXP UM10204
5. SKY130 PDK: skywater-pdk.readthedocs.io

## Troubleshooting

### I2C not responding
- Check CONTROL[7] (EN bit) is set
- Verify clock prescaler configuration
- Check SCL/SDA connections
- Verify slave address match

### Wishbone hangs
- Ensure ACK is generated for all transactions
- Check `wbs_cyc_i` routing (never gate it!)
- Verify address decode logic

### Timing violations
- Check SCL frequency vs. wb_clk_i
- Verify setup/hold times on I2C bus
- Review OpenLane timing reports

### Verification failures
- Check firmware driver logic
- Verify slave register addresses
- Review waveforms in GTKWave
- Enable debug prints in cocotb tests
