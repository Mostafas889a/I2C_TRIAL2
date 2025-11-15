
import os
import shutil
import argparse

parser = argparse.ArgumentParser(description="Run cocotb tests")
parser.add_argument("-extend", help="extend the command")
args = parser.parse_args()

os.environ["CARAVEL_ROOT"] = "/nc/templates/caravel"
os.environ["MCW_ROOT"] = "/nc/templates/mgmt_core_wrapper"

os.chdir("/workspace/I2C_TRIAL2/verilog/dv/cocotb")

command = "python3 /usr/local/bin/caravel_cocotb -test i2c_test -tag i2c_test/RTL-i2c_test/rerun   -sim RTL -corner nom-t  -seed 1763224595 "
if args.extend is not None:
    command += f" {args.extend}"
os.system(command)

shutil.copyfile("/workspace/I2C_TRIAL2/verilog/dv/cocotb/sim/i2c_test/RTL-i2c_test/rerun.py", "/workspace/I2C_TRIAL2/verilog/dv/cocotb/sim/i2c_test/RTL-i2c_test/rerun/RTL-i2c_test/rerun.py")
