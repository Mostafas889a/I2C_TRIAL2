# I2C Caravel User Project

## Initial User Prompt
"Create a user project of 1 i2C connected and don't run it. Try to make slave for i2c and use it for testing"

## Project Overview
This project integrates an I2C master controller into a Caravel user project with a custom I2C slave module for verification. The design demonstrates proper I2C communication protocol implementation suitable for ASIC integration.

## Objectives
1. Integrate EF_I2C IP (I2C master controller) from pre-installed IPs
2. Create a custom I2C slave module for testing purposes
3. Implement proper Wishbone B4 interface for Caravel integration
4. Provide comprehensive verification using caravel-cocotb
5. Prepare the design for silicon-ready hardening (not executed in this phase)

## Design Components
- **I2C Master**: EF_I2C v1.1.0 IP with Wishbone interface
- **I2C Slave**: Custom slave module with register interface for loopback testing
- **Wishbone Infrastructure**: Bus splitter and decoder for peripheral access
- **Interrupt Controller**: Optional PIC for IRQ management

## Project Status
🟡 **In Progress** - Project Setup phase

## Next Steps
1. Link I2C IP using ipm_linker
2. Create I2C slave module
3. Develop user_project and user_project_wrapper
4. Create verification tests
5. Run caravel-cocotb verification